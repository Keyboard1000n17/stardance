class CreateMissionSteps < ActiveRecord::Migration[8.1]
  def change
    create_table :mission_steps do |t|
      t.references :mission, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :title, null: false
      t.text :body, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :mission_steps, [ :mission_id, :position ]
    add_index :mission_steps, :deleted_at
  end
end
