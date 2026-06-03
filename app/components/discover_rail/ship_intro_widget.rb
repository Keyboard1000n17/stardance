# frozen_string_literal: true

module DiscoverRail
  # "What is a ship?" intro video module. Shown when the project isn't on a
  # guided mission (no mission, or a mission without a guide), so projects
  # without guide content still get a primer on shipping.
  class ShipIntroWidget < BaseWidget
    register_as :ship_intro

    def project
      context[:project]
    end

    def render?
      return false if project.nil?
      mission = project.current_mission
      mission.nil? || !mission.has_guide?
    end
  end
end
