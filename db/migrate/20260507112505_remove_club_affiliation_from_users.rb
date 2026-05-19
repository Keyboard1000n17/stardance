class RemoveClubAffiliationFromUsers < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_index :users, column: :airtable_record_id, if_exists: true
      remove_column :users, :airtable_record_id, :string, if_exists: true
      remove_column :users, :club_name, :string, if_exists: true
      remove_column :users, :club_link, :string, if_exists: true
    end
  end
end
