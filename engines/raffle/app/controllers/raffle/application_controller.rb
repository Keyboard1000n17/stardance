module Raffle
  # Base controller for the raffle app. Inherits ActionController::Base directly
  # (NOT the platform's ApplicationController) so the raffle stays independent of
  # platform auth/onboarding. Identity is the GitHub-backed Raffle::Participant.
  class ApplicationController < ActionController::Base
    include Pagy::Method

    protect_from_forgery with: :exception
    layout "raffle/application"

    helper_method :current_participant, :signed_in?

    private

    def current_participant
      return @current_participant if defined?(@current_participant)

      @current_participant = Raffle::Participant.find_by(id: session[:raffle_participant_id])
    end

    def signed_in?
      current_participant.present?
    end

    def require_participant!
      redirect_to root_path, alert: "Sign in with GitHub first." unless signed_in?
    end
  end
end
