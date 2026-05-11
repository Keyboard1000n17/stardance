# == Schema Information
#
# Table name: mission_memberships
#
#  id         :bigint           not null, primary key
#  role       :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  mission_id :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_mission_memberships_on_mission_id  (mission_id)
#  index_mission_memberships_on_user_id     (user_id)
#  index_mission_memberships_unique         (mission_id,user_id,role) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (mission_id => missions.id)
#  fk_rails_...  (user_id => users.id)
#
class Mission::Membership < ApplicationRecord
  self.table_name = "mission_memberships"

  has_paper_trail

  belongs_to :mission, inverse_of: :memberships
  belongs_to :user

  enum :role, { owner: 0, reviewer: 1 }, suffix: true

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: [ :mission_id, :role ] }
end
