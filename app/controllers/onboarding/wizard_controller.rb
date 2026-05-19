class Onboarding::WizardController < ApplicationController
  layout "onboarding"

  before_action :require_signup_email!,    only: %i[welcome birthday submit_birthday]
  before_action :require_teen_attestation!, only: %i[experience submit_experience experience_result
                                                     interests submit_interests interests_result
                                                     name submit_name]

  def start
    if current_user.present?
      redirect_to home_path and return
    end

    email = params[:email].to_s.strip
    if email.blank? || !email.match?(URI::MailTo::EMAIL_REGEXP)
      redirect_to root_path, alert: "Please enter a valid email address." and return
    end

    normalized = normalize_email(email)
    existing = User.find_by(email: normalized)

    if existing&.hca_linked?
      redirect_to helpers.hack_club_auth_path(login_hint: normalized) and return
    end

    if existing&.guest?
      session[:user_id] = existing.id
      redirect_to home_path and return
    end

    signup_session.start!
    signup_session.email = normalized
    redirect_to onboarding_welcome_path
  end

  def welcome; end

  def birthday; end

  def submit_birthday
    case params[:attestation]
    when "teen_13_18"
      signup_session.age_attestation = "teen_13_18"
      redirect_to onboarding_experience_path
    when "ineligible"
      signup_session.clear!
      redirect_to onboarding_age_gate_path
    else
      redirect_to onboarding_birthday_path, alert: "Please pick one."
    end
  end

  def age_gate; end

  def experience; end

  def submit_experience
    level = params[:level].to_s
    unless User.experience_levels.key?(level)
      redirect_to onboarding_experience_path, alert: "Please pick one." and return
    end

    signup_session.experience_level = level
    redirect_to onboarding_experience_result_path
  end

  def experience_result
    @level = signup_session.experience_level
  end

  def interests
    @selected = signup_session.interests || []
  end

  def submit_interests
    selected = Array(params[:interests]) & User::ALLOWED_INTERESTS
    if selected.empty?
      redirect_to onboarding_interests_path, alert: "Pick at least one." and return
    end

    signup_session.interests = selected
    redirect_to onboarding_interests_result_path
  end

  def interests_result
    @interests = signup_session.interests || []
  end

  def name
    @display_name_default = signup_session.display_name.presence || default_name_from_email
  end

  MAX_DISPLAY_NAME_LENGTH = 60

  def submit_name
    display_name = params[:display_name].to_s.strip
    if display_name.blank?
      redirect_to onboarding_name_path, alert: "Please enter a name." and return
    end
    if display_name.length > MAX_DISPLAY_NAME_LENGTH
      redirect_to onboarding_name_path, alert: "That's a really long name — please keep it under #{MAX_DISPLAY_NAME_LENGTH} characters." and return
    end

    signup_session.display_name = display_name
    finalize_signup
  end

  def complete
    authorize :onboarding

    @display_name = current_user.display_name
  end

  private

  def signup_session
    @signup_session ||= SignupSession.new(session)
  end

  def require_signup_email!
    return if signup_session.email.present?
    redirect_to root_path, alert: "Please start signup from the homepage."
  end

  def finalize_signup
    user = User.transaction do
      created = Onboarding::GuestProvisioner.new(
        email:            signup_session.email,
        display_name:     signup_session.display_name,
        age_attestation:  signup_session.age_attestation,
        experience_level: signup_session.experience_level,
        interests:        signup_session.interests || []
      ).call!
      created
    end

    session[:user_id] = user.id
    signup_session.clear!

    redirect_to onboarding_complete_path
  rescue Onboarding::GuestProvisioner::ExistingHcaUser
    signup_session.clear!
    redirect_to helpers.hack_club_auth_path
  end

  def require_teen_attestation!
    return if signup_session.age_attestation == "teen_13_18"
    redirect_to onboarding_birthday_path
  end

  def default_name_from_email
    local = signup_session.email.to_s.split("@").first.to_s
    return nil if local.blank?

    normalized = local.tr("._-", " ")
    normalized.split.map(&:capitalize).join(" ").presence
  end

  def normalize_email(email)
    email.to_s.strip.downcase
  end
end
