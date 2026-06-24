# The product activation funnel, in order. Each step maps to the timestamp at
# which the user first reached it (nil if not reached yet). A user's current
# stage is the furthest step they've reached; they are "stuck" once they've sat
# at that step without advancing.
#
# Rails only reports *which* stage and *when* it was entered — it deliberately
# does not decide "stuck for 2 days" or send anything. That lives downstream:
# Airtable::UserSyncJob mirrors these two fields into the `_users` table, an
# Airtable formula derives days-in-stage, and the existing Airtable -> Loops
# sync sends a one-per-stage re-engagement nudge. Keeping the threshold out of
# Rails means no "have we already notified?" bookkeeping here.
module User::Funnel
  extend ActiveSupport::Concern

  # Canonical order. Mirrors the signup-funnel dashboard.
  STAGES = %i[
    signed_up
    onboarded
    project_created
    hca_linked
    hackatime_connected
    hackatime_project_linked
    devlog_posted
    shop_order_placed
    shipped
  ].freeze

  # Symbol of the furthest funnel step the user has reached (always at least
  # :signed_up, since every user has a created_at).
  def funnel_stage = current_funnel_step.first

  # When the user reached their current stage — i.e. when they got "stuck".
  def funnel_stage_entered_at = current_funnel_step.last

  private

  # [stage, reached_at] for the highest-ordered step with a timestamp.
  def current_funnel_step
    funnel_step_timestamps
      .compact
      .max_by { |stage, _at| STAGES.index(stage) }
  end

  def funnel_step_timestamps
    {
      signed_up: created_at,
      onboarded: onboarded_at,
      project_created: projects.minimum(:created_at),
      hca_linked: hack_club_identity&.created_at,
      hackatime_connected: hackatime_identity&.created_at,
      hackatime_project_linked: hackatime_projects.minimum(:created_at),
      devlog_posted: Post.where(user_id: id, postable_type: "Post::Devlog").minimum(:created_at),
      shop_order_placed: shop_orders.minimum(:created_at),
      shipped: Post.where(user_id: id, postable_type: "Post::ShipEvent").minimum(:created_at)
    }
  end
end
