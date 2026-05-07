class RemovePreferencesFromUsers < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_column :users, :send_votes_to_slack, :boolean, default: false, null: false
      remove_column :users, :leaderboard_optin, :boolean, default: false, null: false
      remove_column :users, :slack_balance_notifications, :boolean, default: false, null: false
      remove_column :users, :send_notifications_for_followed_devlogs, :boolean, default: true, null: false
      remove_column :users, :send_notifications_for_new_followers, :boolean, default: true, null: false
      remove_column :users, :send_notifications_for_new_comments, :boolean, default: true, null: false
      remove_column :users, :special_effects_enabled, :boolean, default: true, null: false
      remove_column :users, :search_engine_indexing_off, :boolean, default: false, null: false
    end
  end
end
