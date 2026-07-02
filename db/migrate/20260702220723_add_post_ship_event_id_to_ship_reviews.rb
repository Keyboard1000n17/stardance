class AddPostShipEventIdToShipReviews < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    unless column_exists?(:certification_ship_reviews, :post_ship_event_id)
      add_column :certification_ship_reviews, :post_ship_event_id, :bigint
    end
    add_index :certification_ship_reviews, :post_ship_event_id, algorithm: :concurrently, if_not_exists: true
  end
end
