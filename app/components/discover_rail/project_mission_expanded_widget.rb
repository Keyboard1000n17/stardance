# frozen_string_literal: true

module DiscoverRail
  # Taller variant of the project-mission module that also previews the next
  # unfinished guide step. Same data/gating as ProjectMissionWidget — only the
  # template differs (it passes variant: :expanded to the partial).
  class ProjectMissionExpandedWidget < ProjectMissionWidget
    register_as :project_mission_expanded
  end
end
