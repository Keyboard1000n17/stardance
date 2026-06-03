# frozen_string_literal: true

module DiscoverRail
  # Discover-rail module showing a project's mission status (attachment,
  # guide progress, shipped state). Reusable on any page that hands it a
  # project via context, e.g.:
  #
  #   discover_rail_widgets :project_mission, context: -> { { project: @project } }
  class ProjectMissionWidget < BaseWidget
    register_as :project_mission

    def project
      context[:project]
    end

    def render?
      project.present? && project.current_mission.present?
    end
  end
end
