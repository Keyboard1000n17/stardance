module User::Moderation
  extend ActiveSupport::Concern

  def ban!(reason: nil)
    update!(banned: true, banned_at: Time.current, banned_reason: reason)
    reject_pending_orders!(reason: reason || "User banned")
    soft_delete_projects!
  end

  def soft_delete_projects!
    projects.find_each do |project|
      project.soft_delete!(force: true)
    end
  end

  def unban!
    update!(banned: false, banned_at: nil, banned_reason: nil)
  end
end
