class VoteableShipEventsQuery
  def self.call(user:, user_agent: nil)
    new(user:).call
  end

  def initialize(user:)
    @user = user
  end

  def call
    held_by_static_prize = Mission::Submission
      .where(payout_path: "static_prize", shop_order_id: nil)
      .where(status: %w[awaiting_certification pending approved])
      .select(:ship_event_id)

    Post::ShipEvent
      .joins(:project)
      .where(certification_status: "approved")
      .where.not(id: @user.votes.select(:ship_event_id))
      .where.not(projects: { id: @user.projects.select(:id) })
      .where.not(projects: { id: @user.project_skips.select(:project_id) })
      .where.not(id: held_by_static_prize)
  end
end
