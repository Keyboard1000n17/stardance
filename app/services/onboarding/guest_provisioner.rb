module Onboarding
  class GuestProvisioner
    class ExistingHcaUser < StandardError; end
    class BlankEmail < ArgumentError; end
    class InvalidAttestation < ArgumentError; end

    attr_reader :email, :display_name, :age_attestation, :experience_level, :interests

    def initialize(email:, display_name:, age_attestation:, experience_level:, interests:)
      @email            = email.to_s.strip.downcase
      @display_name     = display_name.to_s.strip.presence
      @age_attestation  = age_attestation
      @experience_level = experience_level
      @interests        = Array(interests)
    end

    def call!
      raise BlankEmail, "email is required" if email.blank?
      raise InvalidAttestation, "age_attestation must be teen_13_18" unless age_attestation == "teen_13_18"

      attempts = 0
      begin
        attempts += 1
        save_user!
      rescue ActiveRecord::RecordNotUnique
        # Concurrent request created the row between our find_by and save.
        # Retry once: the second pass's find_by will return the just-created row
        # and we'll merge the wizard fields into it.
        retry if attempts < 2
        raise
      end
    end

    private

    def save_user!
      User.transaction do
        user = find_or_initialize_user
        user.assign_attributes(user_attrs)
        user.save!
        user
      end
    end

    def find_or_initialize_user
      existing = User.find_by(email: email)
      raise ExistingHcaUser, "user with email #{email} is already HCA-linked" if existing&.hca_linked?
      existing || User.new(email: email)
    end

    def user_attrs
      {
        display_name:     display_name.presence || User.random_funny_display_name,
        age_attestation:  age_attestation,
        experience_level: experience_level,
        interests:        interests,
        onboarded_at:     Time.current
      }
    end
  end
end
