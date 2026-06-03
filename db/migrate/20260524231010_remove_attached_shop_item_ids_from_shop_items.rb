class RemoveAttachedShopItemIdsFromShopItems < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :shop_items, :attached_shop_item_ids, :bigint, array: true, default: [] }
  end
end
