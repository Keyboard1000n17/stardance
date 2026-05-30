module User::ShopTutorial
  extend ActiveSupport::Concern

  def shop_tutorial_completed? = shop_tutorial_completed_at.present?

  def shop_tutorial_in_progress?
    shop_tutorial_started_at.present? && !shop_tutorial_completed?
  end

  def shop_tutorial_needed?
    hca_linked? && projects.exists? && !shop_tutorial_completed?
  end

  # Like shop_tutorial_needed? but also requires Hackatime to be linked.
  # Used for the sidebar red dot so it doesn't appear immediately on project
  # creation — only once the user has linked Hackatime and is ready to
  # progress toward shipping.
  def shop_tutorial_notify?
    shop_tutorial_needed? && hackatime_identity.present? && identity_verified?
  end

  # Tutorial can only be *finished* once the user has IDV — address collection
  # via HCA requires the linked account to be verified.
  def shop_tutorial_can_complete? = identity_verified?

  def mark_shop_tutorial_started!
    return if shop_tutorial_started_at.present?

    update_columns(shop_tutorial_started_at: Time.current, updated_at: Time.current)
  end

  def mark_shop_tutorial_completed!
    return if shop_tutorial_completed?

    now = Time.current
    update_columns(
      shop_tutorial_started_at: shop_tutorial_started_at || now,
      shop_tutorial_completed_at: now,
      updated_at: now
    )
  end
end
