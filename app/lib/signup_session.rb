class SignupSession
  KEYS = %i[
    start_flow
    start_email
    start_age_attestation
    start_experience_level
    start_interests
    start_display_name
    start_project_attrs
    start_devlog_body
    start_devlog_attachment_ids
  ].freeze

  def initialize(session)
    @session = session
  end

  def started?
    @session[:start_flow].present?
  end

  def start!
    @session[:start_flow] = true
  end

  def email = @session[:start_email]
  def email=(value); @session[:start_email] = value; end

  def age_attestation = @session[:start_age_attestation]
  def age_attestation=(value); @session[:start_age_attestation] = value; end

  def experience_level = @session[:start_experience_level]
  def experience_level=(value); @session[:start_experience_level] = value; end

  def interests = @session[:start_interests]
  def interests=(value); @session[:start_interests] = value; end

  def display_name = @session[:start_display_name]
  def display_name=(value); @session[:start_display_name] = value; end

  def project_attrs = @session[:start_project_attrs]
  def devlog_body = @session[:start_devlog_body]
  def devlog_attachment_ids = @session[:start_devlog_attachment_ids]

  def clear!
    KEYS.each { |k| @session.delete(k) }
  end
end
