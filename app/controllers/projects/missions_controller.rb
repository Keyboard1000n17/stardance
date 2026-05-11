class Projects::MissionsController < ApplicationController
  before_action :require_missions_enabled
  before_action :set_project

  def create
    authorize @project, :update?
    mission = Mission.available.find_by!(slug: params[:mission_slug])

    @project.mission_attachments.create!(mission: mission, attached_at: Time.current)
    track_funnel("mission_attached_post_creation", mission: mission)

    redirect_to @project, notice: "Attached to the #{mission.name} mission."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @project, alert: e.record.errors.full_messages.to_sentence
  rescue ActiveRecord::RecordNotFound
    redirect_to @project, alert: "Mission not found."
  end

  def destroy
    authorize @project, :update?
    attachment = @project.mission_attachments.where(detached_at: nil).order(attached_at: :desc).first
    return redirect_to(@project, alert: "No mission attached.") unless attachment

    mission = attachment.mission
    attachment.detach!
    track_funnel("mission_detached", mission: mission)

    redirect_to @project, notice: "Detached from the #{mission.name} mission."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def require_missions_enabled
    return if Flipper.enabled?(:missions, current_user)
    raise ActionController::RoutingError, "Not Found"
  end

  def track_funnel(event, mission:)
    return unless defined?(FunnelTrackerService)
    FunnelTrackerService.track(
      event_name: event,
      user: current_user,
      properties: { project_id: @project.id, mission_id: mission.id, mission_slug: mission.slug }
    )
  end
end
