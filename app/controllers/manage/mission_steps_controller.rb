class Manage::MissionStepsController < Manage::BaseController
  before_action :set_step, only: [ :update, :destroy ]

  def create
    step = @mission.steps.new(step_params.merge(position: next_position))
    step.save!
    redirect_to edit_manage_mission_path(@mission.slug), notice: "Step added."
  end

  def update
    if step_params[:direction].present?
      reorder!(step_params[:direction])
    else
      @step.update!(step_params.except(:direction))
    end
    redirect_to edit_manage_mission_path(@mission.slug), notice: "Step updated."
  end

  def destroy
    @step.update!(deleted_at: Time.current)
    redirect_to edit_manage_mission_path(@mission.slug), notice: "Step removed."
  end

  private

  def set_step
    @step = @mission.steps.find(params[:id])
  end

  def step_params
    params.require(:mission_step).permit(:title, :body, :direction)
  end

  def next_position
    (@mission.steps.maximum(:position) || 0) + 1
  end

  # Swap positions with the adjacent step in the requested direction.
  def reorder!(direction)
    siblings = @mission.steps.ordered.to_a
    idx = siblings.index { |s| s.id == @step.id }
    return unless idx

    target_idx = direction == "up" ? idx - 1 : idx + 1
    return if target_idx < 0 || target_idx >= siblings.length

    other = siblings[target_idx]
    Mission::Step.transaction do
      mine, theirs = @step.position, other.position
      @step.update!(position: theirs)
      other.update!(position: mine)
    end
  end
end
