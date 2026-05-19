module Admin
  class MissionsController < Admin::ApplicationController
    before_action :set_mission, only: [ :show, :edit, :update, :destroy, :restore ]

    def index
      scope = Mission.with_deleted.order(created_at: :desc)
      scope = scope.where(enabled: false) if params[:filter] == "disabled"
      scope = scope.where.not(deleted_at: nil) if params[:filter] == "deleted"
      @missions = scope.limit(200)
      @submission_counts = Mission::Submission.where(mission_id: @missions.map(&:id)).group(:mission_id).count
    end

    def new
      @mission = Mission.new
    end

    def create
      @mission = Mission.new(mission_params)
      if @mission.save
        redirect_to admin_mission_path(@mission.slug), notice: "Mission created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @submissions = @mission.submissions.order(created_at: :desc).limit(50)

      mission_versions = PaperTrail::Version.where(item_type: "Mission", item_id: @mission.id.to_s)
      child_versions   = PaperTrail::Version.where(
        item_type: %w[Mission::Step Mission::Prize Mission::Membership Mission::ShopUnlock],
        item_id: child_audit_ids
      )
      @versions = mission_versions.or(child_versions).order(created_at: :desc).limit(50)
    end

    def edit
      @steps       = @mission.steps.ordered
      @prizes      = @mission.prizes.ordered.includes(:shop_item)
      @memberships = @mission.memberships.includes(:user).order(:role, :id)
      @unlocks     = @mission.shop_unlocks.includes(:shop_item)
    end

    def update
      if @mission.update(mission_params)
        redirect_to admin_mission_path(@mission.slug), notice: "Mission updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @mission.update!(deleted_at: Time.current, enabled: false)
      redirect_to admin_missions_path, notice: "Mission soft-deleted."
    end

    def restore
      @mission.update!(deleted_at: nil)
      redirect_to admin_mission_path(@mission.slug), notice: "Mission restored."
    end

    private

    def set_mission
      @mission = Mission.with_deleted.find_by!(slug: params[:slug])
    end

    # PaperTrail's versions.item_id is a varchar — pluck mission child ids and
    # cast to strings so the IN clause hits the (item_type, item_id) index.
    def child_audit_ids
      ids = @mission.steps.with_deleted.pluck(:id) +
            @mission.prizes.with_deleted.pluck(:id) +
            @mission.memberships.pluck(:id) +
            @mission.shop_unlocks.pluck(:id)
      ids.map(&:to_s)
    end

    def mission_params
      params.require(:mission).permit(
        :slug, :name, :description, :difficulty,
        :enabled, :start_at, :end_at, :featured_at,
        :achievement_name, :achievement_description, :icon, :banner
      )
    end
  end
end
