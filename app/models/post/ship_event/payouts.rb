module Post::ShipEvent::Payouts
  extend ActiveSupport::Concern

  PAYOUT_CURVE_VERSION = "flavortown_percentile_v1"
  BROADCAST_CHANNEL_ID = "C0AFB0JU00P"

  included do
    has_one :certification_ysws_review,
            class_name: "Certification::Ysws",
            foreign_key: :post_ship_event_id,
            inverse_of: :post_ship_event

    scope :approved, -> { where(certification_status: "approved") }
    scope :unpaid, -> { where(payout: nil) }
    scope :voting_payout_path, -> {
      left_outer_joins(:mission_submission)
        .where(
          "mission_submissions.id IS NULL OR (mission_submissions.payout_path = ? AND mission_submissions.status <> ?)",
          "voting",
          "rejected"
        )
    }
    scope :ready_for_payout, -> {
      approved.unpaid.voting_payout_path.where("post_ship_events.votes_count >= ?", Post::ShipEvent::VOTES_REQUIRED_FOR_PAYOUT)
    }
  end

  class_methods do
    def refresh_payouts!
      sample = payout_score_sample

      ready_for_payout.includes(:mission_submission, :certification_ysws_review, post: [ :project, :user ]).find_each do |ship_event|
        ship_event.refresh_payout_score!(sample)
        ship_event.issue_payout!
      end
    end

    def payout_score_sample
      rows = Vote.payout_countable
                 .where(ship_event_id: voting_payout_path.select(:id))
                 .pluck(:ship_event_id, *Vote.score_columns)

      scores_by_ship = rows.group_by(&:first).transform_values { |ship_rows| ship_rows.map { |row| row.drop(1) } }
      medians_by_ship = scores_by_ship.transform_values { |ship_rows| payout_medians(ship_rows) }

      {
        scores_by_ship: scores_by_ship,
        overall_scores: medians_by_ship.values.filter_map { |medians| average(medians.values.compact) },
        category_values: Vote::SCORE_COLUMNS_BY_CATEGORY.keys.index_with do |category|
          medians_by_ship.values.filter_map { |medians| medians[category] }
        end
      }
    end

    def payout_medians(score_rows)
      Vote::SCORE_COLUMNS_BY_CATEGORY.keys.each_with_index.to_h do |category, index|
        [ category, median(score_rows.filter_map { |row| row[index] }) ]
      end
    end

    def median(values)
      sorted = values.sort
      return nil if sorted.empty?

      midpoint = sorted.length / 2
      if sorted.length.odd?
        sorted[midpoint]
      else
        (sorted[midpoint - 1] + sorted[midpoint]) / 2.0
      end
    end

    def average(values)
      values.sum.to_f / values.length if values.any?
    end

    def percentile_rank(value, values)
      return nil if value.nil? || values.empty?

      below = values.count { |current| current < value }
      equal = values.count { |current| current == value }

      return 50.0 if below.zero? && equal == values.length

      ((below + 0.5 * equal) / values.length.to_f * 100).round(2)
    end
  end

  def refresh_payout_score!(sample = self.class.payout_score_sample)
    medians = self.class.payout_medians(sample[:scores_by_ship].fetch(id, []))
    overall = self.class.average(medians.values.compact)
    percentiles = medians.transform_values.with_index do |median, index|
      category = Vote::SCORE_COLUMNS_BY_CATEGORY.keys[index]
      self.class.percentile_rank(median, sample[:category_values].fetch(category, []))
    end

    update_columns(
      originality_median: medians[:originality],
      technical_median: medians[:technicality],
      usability_median: medians[:usability],
      storytelling_median: medians[:storytelling],
      overall_score: overall,
      originality_percentile: percentiles[:originality],
      technical_percentile: percentiles[:technicality],
      usability_percentile: percentiles[:usability],
      storytelling_percentile: percentiles[:storytelling],
      overall_percentile: self.class.percentile_rank(overall, sample[:overall_scores]),
      updated_at: Time.current
    )
  end

  def issue_payout!
    if payout_ready_except_vote_balance? && payout_recipient.vote_balance.negative?
      notify_vote_deficit
      return false
    end

    return false unless payout_eligible?

    with_lock do
      return false unless payout_eligible?

      refresh_payout_score! if overall_percentile.nil?

      amount = payout_amount
      return false unless amount&.positive?

      self.payout = amount
      self.multiplier = payout_multiplier
      self.hours_at_payout = hours
      self.payout_basis_overall_score = overall_score
      self.payout_basis_percentile = overall_percentile
      self.payout_basis_locked_at = Time.current
      self.payout_curve_version = PAYOUT_CURVE_VERSION
      self.payout_blessing = payout_blessing

      save!
      create_payout_ledger_entry!
    end

    notify_payout_issued
    broadcast_payout
    true
  end

  def payout_eligible?
    payout_ready_except_vote_balance? &&
      !payout_recipient.vote_balance.negative? &&
      hours.positive?
  end

  def payout_recipient
    post&.user
  end

  def hours
    if reviewed_hardware_minutes
      reviewed_hardware_minutes / 60.0
    else
      hours_at_ship.to_f
    end
  end

  private
    def payout_ready_except_vote_balance?
      certification_status == "approved" &&
        payout.blank? &&
        voting_payout_path? &&
        votes.payout_countable.count >= Post::ShipEvent::VOTES_REQUIRED_FOR_PAYOUT &&
        payout_recipient.present?
    end

    def voting_payout_path?
      submission = mission_submission
      submission.nil? || (submission.payout_path == "voting" && !submission.rejected?)
    end

    def reviewed_hardware_minutes
      review = certification_ysws_review
      review.approved_minutes_total if project&.hardware? && review&.devlog_reviews&.any?(&:reviewed?)
    end

    def payout_amount
      return nil if payout_multiplier.nil?

      apply_payout_blessing((hours * payout_multiplier).round)
    end

    def payout_multiplier
      return nil if overall_percentile.nil?

      (dollars_per_hour_for_percentile(overall_percentile) * game_constants.tickets_per_dollar.to_f).round(6)
    end

    def dollars_per_hour_for_percentile(percentile)
      low = game_constants.lowest_dollar_per_hour.to_f
      high = game_constants.highest_dollar_per_hour.to_f
      low + (high - low) * ((percentile.to_f / 100.0).clamp(0.0, 1.0) ** 1.745427173)
    end

    def payout_blessing
      payout_recipient.vote_verdict&.verdict || "neutral"
    end

    def apply_payout_blessing(amount)
      case payout_blessing
      when "blessed" then (amount * 1.2).round
      when "cursed" then (amount * 0.5).round
      else amount
      end
    end

    def create_payout_ledger_entry!
      payout_recipient.ledger_entries.create!(
        ledgerable: self,
        amount: payout,
        reason: "Ship event payout: #{project&.title || 'Unknown project'}",
        created_by: "ship_event_payout"
      )
    end

    def notify_payout_issued
      Notifications::Payouts::ShipEventIssued.notify(
        recipient: payout_recipient,
        record: self,
        params: payout_notification_params
      )
    end

    def notify_vote_deficit
      cache_key = "vote_deficit_notified:#{id}"
      return if Rails.cache.exist?(cache_key)

      Rails.cache.write(cache_key, true, expires_in: 6.hours)
      Notifications::Payouts::VoteDeficitBlocked.notify(
        recipient: payout_recipient,
        record: self,
        params: {
          "votes_needed" => payout_recipient.vote_balance.abs,
          "project_title" => project&.title
        }
      )
    end

    def broadcast_payout
      SendSlackDmJob.perform_later(
        BROADCAST_CHANNEL_ID,
        nil,
        blocks_path: "notifications/payouts/broadcast",
        locals: payout_notification_params.merge(
          project_url: "https://stardance.hackclub.com/projects/#{project&.id}",
          recipient_name: payout_recipient.display_name
        ).symbolize_keys
      )
    end

    def payout_notification_params
      {
        "project_id" => project&.id,
        "project_title" => project&.title || "Unknown project",
        "ship_date" => post&.created_at&.strftime("%b %-d, %Y"),
        "hours" => hours.round(2),
        "stardust" => payout.to_i,
        "multiplier" => multiplier&.round(2),
        "blessing" => payout_blessing
      }
    end

    def game_constants
      Rails.configuration.game_constants
    end
end
