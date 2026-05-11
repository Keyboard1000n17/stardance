class AddUniqueIndexForWelcomeGrant < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :ledger_entries, [ :user_id, :reason ],
              unique: true,
              where: "reason = 'Free Stickers Welcome Grant'",
              name: "index_ledger_entries_unique_welcome_grant",
              algorithm: :concurrently
  end
end
