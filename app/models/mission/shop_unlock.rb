# == Schema Information
#
# Table name: mission_shop_unlocks
#
#  id           :bigint           not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  mission_id   :bigint           not null
#  shop_item_id :bigint           not null
#
# Indexes
#
#  index_mission_shop_unlocks_on_mission_id    (mission_id)
#  index_mission_shop_unlocks_on_shop_item_id  (shop_item_id)
#  index_mission_shop_unlocks_unique           (mission_id,shop_item_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (mission_id => missions.id)
#  fk_rails_...  (shop_item_id => shop_items.id)
#
class Mission::ShopUnlock < ApplicationRecord
  self.table_name = "mission_shop_unlocks"

  has_paper_trail

  belongs_to :mission, inverse_of: :shop_unlocks
  belongs_to :shop_item

  validates :shop_item_id, uniqueness: { scope: :mission_id }
end
