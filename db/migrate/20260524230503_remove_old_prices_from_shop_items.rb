class RemoveOldPricesFromShopItems < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :shop_items, :old_prices, :integer, array: true, default: [] }
  end
end
