class CreateMissionSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :mission_submissions do |t|
      t.references :ship_event,
                   null: false,
                   foreign_key: { to_table: :post_ship_events }
      t.references :mission, null: false, foreign_key: true
      t.string :status, null: false
      t.string :payout_path, null: false
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.datetime :reviewed_at
      t.text :rejection_message
      t.references :chosen_prize, foreign_key: { to_table: :mission_prizes }
      t.references :shop_order, foreign_key: true
      t.datetime :deleted_at

      t.timestamps
    end

    # One non-soft-deleted submission per ship_event.
    # (Bypassing a submission soft-deletes it, freeing the ship to take a new
    #  submission via a re-attached mission later if the user wanted.)
    add_index :mission_submissions, :ship_event_id, unique: true,
              where: "deleted_at IS NULL",
              name: "index_mission_submissions_active_per_ship_event"

    add_index :mission_submissions, [ :mission_id, :status ]
    add_index :mission_submissions, [ :status, :created_at ]
    add_index :mission_submissions, :shop_order_id, where: "shop_order_id IS NOT NULL",
              name: "index_mission_submissions_with_shop_order"
    add_index :mission_submissions, :deleted_at
  end
end
