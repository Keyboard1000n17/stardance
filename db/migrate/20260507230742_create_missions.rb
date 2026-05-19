class CreateMissions < ActiveRecord::Migration[8.1]
  def change
    create_table :missions do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.text :description, null: false
      t.boolean :enabled, default: true, null: false
      t.datetime :start_at
      t.datetime :end_at
      t.datetime :featured_at
      t.string :achievement_name
      t.text :achievement_description
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :missions, :slug, unique: true
    add_index :missions, :enabled
    add_index :missions, :featured_at
    add_index :missions, :deleted_at
  end
end
