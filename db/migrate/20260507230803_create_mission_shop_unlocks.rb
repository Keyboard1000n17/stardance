class CreateMissionShopUnlocks < ActiveRecord::Migration[8.1]
  def change
    create_table :mission_shop_unlocks do |t|
      t.references :mission,   null: false, foreign_key: true
      t.references :shop_item, null: false, foreign_key: true

      t.timestamps
    end

    add_index :mission_shop_unlocks, [ :mission_id, :shop_item_id ], unique: true,
              name: "index_mission_shop_unlocks_unique"
  end
end
