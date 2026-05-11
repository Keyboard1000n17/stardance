class Projects::MissionStepCompletionsController < ApplicationController
  before_action :require_missions_enabled
  before_action :set_project
  before_action :set_step

  def create
    authorize @project, :update?
    completion = @project.mission_step_completions.find_or_initialize_by(mission_step_id: @step.id)
    completion.completed_at ||= Time.current
    completion.save!
    redirect_to @project
  end

  def destroy
    authorize @project, :update?
    @project.mission_step_completions.where(mission_step_id: @step.id).destroy_all
    redirect_to @project
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_step
    @step = Mission::Step.find(params[:mission_step_id])
  end

  def require_missions_enabled
    return if Flipper.enabled?(:missions, current_user)
    raise ActionController::RoutingError, "Not Found"
  end
end
