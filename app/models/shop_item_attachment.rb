# == Schema Information
#
# Table name: shop_item_attachments
#
#  id                :bigint           not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  accessory_item_id :bigint           not null
#  parent_item_id    :bigint           not null
#
# Indexes
#
#  idx_on_parent_item_id_accessory_item_id_9641b2d0dd  (parent_item_id,accessory_item_id) UNIQUE
#  index_shop_item_attachments_on_accessory_item_id    (accessory_item_id)
#  index_shop_item_attachments_on_parent_item_id       (parent_item_id)
#
# Foreign Keys
#
#  fk_rails_...  (accessory_item_id => shop_items.id) ON DELETE => cascade
#  fk_rails_...  (parent_item_id => shop_items.id) ON DELETE => cascade
#
class ShopItemAttachment < ApplicationRecord
  belongs_to :parent_item, class_name: "ShopItem"
  belongs_to :accessory_item, class_name: "ShopItem"
end
