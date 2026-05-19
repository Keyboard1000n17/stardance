class RemoveUnusedUserMetricColumns < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_column :users, :vote_anonymously, :boolean, default: false, null: false, if_exists: true
      remove_column :users, :stardust_clicks, :integer, default: 0, null: false, if_exists: true
      remove_column :users, :metrics_synced_at, :datetime, if_exists: true
      remove_column :users, :flavortown_message_count_14d, :integer, if_exists: true
      remove_column :users, :flavortown_support_message_count_14d, :integer, if_exists: true
      remove_column :users, :projects_count, :integer, if_exists: true
      remove_column :users, :projects_shipped_count, :integer, if_exists: true
      remove_column :users, :slack_messages_updated_at, :datetime, if_exists: true
    end
  end
end
