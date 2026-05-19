require "test_helper"

class Onboarding::WizardControllerTest < ActionDispatch::IntegrationTest
  test "POST /onboarding/start with valid email seeds session and redirects to welcome" do
    post onboarding_start_path, params: { email: "fresh@example.com" }
    assert_redirected_to onboarding_welcome_path
    assert_equal "fresh@example.com", session[:start_email]
    assert session[:start_flow]
  end

  test "POST /onboarding/start with invalid email re-renders root with alert" do
    post onboarding_start_path, params: { email: "not-an-email" }
    assert_redirected_to root_path
    assert_nil session[:start_email]
  end

  test "GET /onboarding/welcome without start_email redirects to root" do
    get onboarding_welcome_path
    assert_redirected_to root_path
  end

  test "POST /onboarding/birthday with teen_13_18 advances and writes session" do
    post onboarding_start_path, params: { email: "teen@example.com" }
    post onboarding_birthday_path, params: { attestation: "teen_13_18" }
    assert_redirected_to onboarding_experience_path
    assert_equal "teen_13_18", session[:start_age_attestation]
  end

  test "POST /onboarding/birthday with ineligible clears session and routes to age-gate" do
    post onboarding_start_path, params: { email: "tooold@example.com" }
    post onboarding_birthday_path, params: { attestation: "ineligible" }
    assert_redirected_to onboarding_age_gate_path
    assert_nil session[:start_email]
    assert_nil session[:start_age_attestation]
  end

  test "experience step gated when no teen attestation" do
    post onboarding_start_path, params: { email: "x@example.com" }
    get onboarding_experience_path
    assert_redirected_to onboarding_birthday_path
  end

  test "full happy path creates a guest user, signs them in, and redirects with welcome=1" do
    post onboarding_start_path, params: { email: "happy@example.com" }
    post onboarding_birthday_path, params: { attestation: "teen_13_18" }
    post onboarding_experience_path, params: { level: "some" }
    post onboarding_interests_path, params: { interests: %w[web_dev hardware] }

    assert_difference "User.count", 1 do
      post onboarding_name_path, params: { display_name: "Happy Hacker" }
    end

    assert_redirected_to onboarding_complete_path
    user = User.find_by(email: "happy@example.com")
    assert_equal "Happy Hacker", user.display_name
    assert_equal "teen_13_18", user.age_attestation
    assert_equal "some", user.experience_level
    assert_equal %w[web_dev hardware], user.interests
    assert user.onboarded?
    assert user.guest?
    assert_equal user.id, session[:user_id]
    assert_nil session[:start_email]
  end
end
