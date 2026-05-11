class CreateMissionMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :mission_memberships do |t|
      t.references :mission, null: false, foreign_key: true
      t.references :user,    null: false, foreign_key: true
      t.integer :role, null: false

      t.timestamps
    end

    add_index :mission_memberships, [ :mission_id, :user_id, :role ], unique: true,
              name: "index_mission_memberships_unique"
  end
end
