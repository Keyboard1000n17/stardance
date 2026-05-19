# frozen_string_literal: true

module Projects
  class ShelfCardComponent < ViewComponent::Base
    attr_reader :project

    def initialize(project:)
      @project = project
    end

    def description
      project.display_description.presence || project.description
    end
  end
end
