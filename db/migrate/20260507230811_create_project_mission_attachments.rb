class CreateProjectMissionAttachments < ActiveRecord::Migration[8.1]
  def change
    create_table :project_mission_attachments do |t|
      t.references :project, null: false, foreign_key: true
      t.references :mission, null: false, foreign_key: true
      t.datetime :attached_at, null: false
      t.datetime :detached_at
      t.datetime :deleted_at

      t.timestamps
    end

    # Same-mission active double-attach prevention. Soft-deleted or detached
    # rows don't count, so re-attaching to the same mission later is fine.
    add_index :project_mission_attachments, [ :project_id, :mission_id ], unique: true,
              where: "detached_at IS NULL AND deleted_at IS NULL",
              name: "index_project_mission_attachments_active"
    add_index :project_mission_attachments, :deleted_at
  end
end
