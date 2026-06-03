class RemoveAccessoryIdsFromShopOrders < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :shop_orders, :accessory_ids, :bigint, array: true, default: [] }
  end
end
