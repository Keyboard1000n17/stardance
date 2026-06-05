# frozen_string_literal: true

module DiscoverRail
  class RaffleWidget < BaseWidget
    register_as :raffle

    def render?
      user.present? && enrolled?
    end

    def participant
      @participant ||= Raffle::Participant.find_by(user_id: user.id)
    end

    def week
      @week ||= Raffle::Week.current
    end

    def entry_count
      return 0 unless participant && week
      participant.entry_count(week)
    end

    def enrolled?
      participant.present?
    end

    def raffle_eligible?
      user.geocoded_country.presence&.in?(%w[US CA])
    end

    def verified_count
      return 0 unless participant
      participant.referrals.status_verified.count
    end

    def pending_count
      return 0 unless participant
      participant.referrals.status_pending.count
    end

    def referral_url
      participant&.referral_url(:web)
    end
  end
end
