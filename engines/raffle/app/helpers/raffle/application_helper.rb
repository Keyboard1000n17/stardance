module Raffle
  module ApplicationHelper
    # The only thing we ever surface about a referred user is the display name
    # they chose at sign-up — never their email, real name, or any other PII.
    def referral_display_name(user)
      return "A new participant" unless user

      user.display_name.presence || "A new participant"
    end

    # GitHub avatar when present, otherwise one of the bundled guest-star
    # avatars (picked stably from the participant id) so mock/dev users and
    # anyone without a GitHub image still get a face.
    def participant_avatar_url(participant)
      return if participant.nil?

      participant.avatar_url.presence ||
        asset_path("avatars/guest_star_#{(participant.id % 3) + 1}.png")
    end
  end
end
