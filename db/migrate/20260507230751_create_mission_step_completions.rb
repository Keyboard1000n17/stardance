class CreateMissionStepCompletions < ActiveRecord::Migration[8.1]
  def change
    create_table :mission_step_completions do |t|
      t.references :project, null: false, foreign_key: true
      t.references :mission_step, null: false, foreign_key: true
      t.datetime :completed_at

      t.timestamps
    end

    add_index :mission_step_completions, [ :project_id, :mission_step_id ], unique: true,
              name: "index_mission_step_completions_unique"
  end
end
