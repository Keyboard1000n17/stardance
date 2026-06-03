class RemoveSidequestColumnsFromShopItems < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_column :shop_items, :requires_sidequest_entry, :boolean if column_exists?(:shop_items, :requires_sidequest_entry)
      remove_column :shop_items, :sidequest_id, :bigint if column_exists?(:shop_items, :sidequest_id)
      remove_column :shop_items, :sidequest_approval_required, :boolean if column_exists?(:shop_items, :sidequest_approval_required)
    end
  end
end
