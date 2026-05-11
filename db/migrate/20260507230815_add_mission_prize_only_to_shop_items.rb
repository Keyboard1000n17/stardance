class AddMissionPrizeOnlyToShopItems < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :shop_items, :mission_prize_only, :boolean, default: false, null: false
    add_index :shop_items, :mission_prize_only, algorithm: :concurrently
  end
end
