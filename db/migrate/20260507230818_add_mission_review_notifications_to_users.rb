class AddMissionReviewNotificationsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :mission_review_notifications, :boolean, default: true, null: false
  end
end
