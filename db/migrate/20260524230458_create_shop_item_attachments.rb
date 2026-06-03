class CreateShopItemAttachments < ActiveRecord::Migration[8.1]
  def change
    create_table :shop_item_attachments do |t|
      t.references :parent_item, null: false, foreign_key: { to_table: :shop_items, on_delete: :cascade }
      t.references :accessory_item, null: false, foreign_key: { to_table: :shop_items, on_delete: :cascade }

      t.timestamps
    end

    add_index :shop_item_attachments, [ :parent_item_id, :accessory_item_id ], unique: true
  end
end
