class Manage::MissionsController < Manage::BaseController
  before_action :set_body_class

  def show
    redirect_to edit_manage_mission_path(@mission.slug)
  end

  def edit
    @steps       = @mission.steps.ordered
    @prizes      = @mission.prizes.ordered.includes(:shop_item)
    @memberships = @mission.memberships.includes(:user).order(:role, :id)
    @unlocks     = @mission.shop_unlocks.includes(:shop_item)
  end

  def update
    if @mission.update(mission_params)
      redirect_to edit_manage_mission_path(@mission.slug), notice: "Mission updated."
    else
      @steps       = @mission.steps.ordered
      @prizes      = @mission.prizes.ordered.includes(:shop_item)
      @memberships = @mission.memberships.includes(:user).order(:role, :id)
      @unlocks     = @mission.shop_unlocks.includes(:shop_item)
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_body_class
    @body_class = "app-layout-page"
  end

  def mission_params
    params.require(:mission).permit(
      :name, :description, :difficulty,
      :enabled, :start_at, :end_at, :featured_at,
      :achievement_name, :achievement_description, :icon, :banner
    )
  end
end
