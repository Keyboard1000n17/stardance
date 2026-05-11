class CreateMissionPrizes < ActiveRecord::Migration[8.1]
  def change
    create_table :mission_prizes do |t|
      t.references :mission,   null: false, foreign_key: true
      t.references :shop_item, null: false, foreign_key: true
      t.integer :position, default: 0, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    # Active (non-soft-deleted) prizes can't link the same mission/shop_item twice.
    add_index :mission_prizes, [ :mission_id, :shop_item_id ], unique: true,
              where: "deleted_at IS NULL",
              name: "index_mission_prizes_active_unique"
    add_index :mission_prizes, :deleted_at
  end
end
