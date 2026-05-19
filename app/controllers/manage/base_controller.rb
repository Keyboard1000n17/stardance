class Manage::BaseController < ApplicationController
  before_action :require_missions_enabled
  before_action :set_mission
  before_action :authorize_mission_management

  private

  def set_mission
    slug = params[:mission_slug] || params[:slug]
    @mission = Mission.find_by!(slug: slug)
  end

  def authorize_mission_management
    authorize @mission, :manage?
  end

  def require_missions_enabled
    return if Flipper.enabled?(:missions, current_user)
    raise ActionController::RoutingError, "Not Found"
  end
end
