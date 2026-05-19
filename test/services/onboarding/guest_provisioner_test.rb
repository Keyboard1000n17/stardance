require "test_helper"

class Onboarding::GuestProvisionerTest < ActiveSupport::TestCase
  setup do
    @params = {
      email:            "newkid@example.com",
      display_name:     "Newbie",
      age_attestation:  "teen_13_18",
      experience_level: "little",
      interests:        %w[web_dev game_dev]
    }
  end

  test "creates a guest user with wizard fields" do
    assert_difference "User.count", 1 do
      user = Onboarding::GuestProvisioner.new(**@params).call!
      assert_equal "newkid@example.com", user.email
      assert_equal "Newbie", user.display_name
      assert_equal "teen_13_18", user.age_attestation
      assert_equal "little", user.experience_level
      assert_equal %w[web_dev game_dev], user.interests
      assert user.onboarded?
      assert user.guest?
      refute user.hca_linked?
    end
  end

  test "raises RecordInvalid when interests contain values outside ALLOWED_INTERESTS" do
    assert_raises ActiveRecord::RecordInvalid do
      Onboarding::GuestProvisioner.new(**@params.merge(interests: %w[web_dev hacking_the_planet])).call!
    end
  end

  test "normalizes email" do
    user = Onboarding::GuestProvisioner.new(**@params.merge(email: " UPPER@EXAMPLE.com ")).call!
    assert_equal "upper@example.com", user.email
  end

  test "returns existing guest when email matches a guest row" do
    existing = Onboarding::GuestProvisioner.new(**@params).call!

    assert_no_difference "User.count" do
      user = Onboarding::GuestProvisioner.new(**@params.merge(display_name: "Different")).call!
      assert_equal existing.id, user.id
      assert_equal "Different", user.reload.display_name
    end
  end

  test "raises when email belongs to an HCA-linked user" do
    hca_user = User.joins(:hack_club_identity).first
    skip "no HCA-linked fixture user available" unless hca_user&.hca_linked?

    assert_raises Onboarding::GuestProvisioner::ExistingHcaUser do
      Onboarding::GuestProvisioner.new(**@params.merge(email: hca_user.email)).call!
    end
  end

  test "raises when attestation is not teen_13_18" do
    assert_raises ArgumentError do
      Onboarding::GuestProvisioner.new(**@params.merge(age_attestation: "ineligible")).call!
    end
  end

  test "raises when email is blank" do
    assert_raises ArgumentError do
      Onboarding::GuestProvisioner.new(**@params.merge(email: "")).call!
    end
  end
end
