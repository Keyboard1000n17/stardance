module Raffle
  class SessionsController < ApplicationController
    def create
      auth = request.env["omniauth.auth"]
      return redirect_to(root_path, alert: "GitHub sign-in failed.") if auth.blank?

      participant = Raffle::Participant.from_github(auth)
      sign_in(participant)
      redirect_to dashboard_path
    end

    def failure
      redirect_to root_path, alert: "GitHub sign-in failed."
    end

    def destroy
      reset_session
      redirect_to root_path
    end

    if Rails.env.development? || Rails.env.test?
      # Demo bypass — log in (creating if needed) a fake participant without
      # real GitHub OAuth creds. e.g. /dev_login/ada
      def dev_login
        handle = dev_login_handle
        participant = Raffle::Participant.find_or_create_by!(github_uid: "dev-#{handle}") do |p|
          p.github_login = handle
          p.name = handle.titleize
          p.github_email = "#{handle}@dev.local"
        end
        sign_in(participant)
        redirect_to dashboard_path
      end
    end

    private

    def sign_in(participant)
      reset_session
      session[:raffle_participant_id] = participant.id
    end

    if Rails.env.development? || Rails.env.test?
      def dev_login_handle
        handle = params[:handle].presence&.parameterize(separator: "_")
        handle = handle.first(40) if handle.present?
        handle.presence || "devuser"
      end
    end
  end
end
