class AdminPolicy < ApplicationPolicy
  def index?
    user.admin? || user.fraud_dept? || user.shop_manager? || user.helper?
  end

  def access_admin_endpoints?
    user.admin? || user.fraud_dept? || user.shop_manager? || user.helper?
  end

  def access_fulfillment_view?
    user.admin? || user.fulfillment_person?
  end

  def access_ship_review?
    user.admin? || user.has_role?(:project_certifier)
  end

  def access_ysws_review?
    user.admin? || user.has_role?(:guardian_of_integrity)
  end

  def access_blazer?
    user.admin?
  end

  def access_flipper?
    user.admin?
  end

  def access_jobs?
    user.admin?
  end

  def view_leaderboard?
    user.admin? || user.fulfillment_person? || user.fraud_dept?
  end

  # "Awaiting verification" and "on hold" are fraud-review states. Only admins
  # and the fraud dept action them, so their status filter chips are hidden
  # from fulfillment helpers (who are locked to the fulfillment view).
  def view_fraud_review_filters?
    user.admin? || user.fraud_dept?
  end

  # Full shop catalogue management — admins only.
  def manage_shop?
    user.admin?
  end

  # Editing shop items, including shop managers on their own draft items.
  # Mirrors Admin::ShopItemPolicy#update? (admin || shop_manager).
  def manage_draft_shop_items?
    user.admin? || user.shop_manager?
  end
end
