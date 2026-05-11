module Admin
  class MissionsBaseController < Admin::ApplicationController
    before_action :set_mission

    private

    def set_mission
      @mission = Mission.with_deleted.find_by!(slug: params[:mission_slug])
    end
  end
end
