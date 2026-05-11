# == Schema Information
#
# Table name: mission_step_completions
#
#  id              :bigint           not null, primary key
#  completed_at    :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  mission_step_id :bigint           not null
#  project_id      :bigint           not null
#
# Indexes
#
#  index_mission_step_completions_on_mission_step_id  (mission_step_id)
#  index_mission_step_completions_on_project_id       (project_id)
#  index_mission_step_completions_unique              (project_id,mission_step_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (mission_step_id => mission_steps.id)
#  fk_rails_...  (project_id => projects.id)
#
class Mission::StepCompletion < ApplicationRecord
  self.table_name = "mission_step_completions"

  has_paper_trail

  belongs_to :project
  belongs_to :mission_step, class_name: "Mission::Step"

  validates :project_id, uniqueness: { scope: :mission_step_id }

  scope :completed, -> { where.not(completed_at: nil) }
end
