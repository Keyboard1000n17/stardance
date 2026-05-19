class Missions::OgImagesController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_mission

  def show
    skip_authorization

    png_data = OgImage::Missions.new(@mission).to_png

    expires_in 1.hour, public: true
    send_data png_data, type: "image/png", disposition: "inline"
  end

  private

  def set_mission
    @mission = Mission.find_by!(slug: params[:mission_slug])
  end
end
