class AddPostShipEventFkToShipReviews < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    unless foreign_key_exists?(:certification_ship_reviews, :post_ship_events)
      add_foreign_key :certification_ship_reviews, :post_ship_events,
                      column: :post_ship_event_id, on_delete: :nullify, validate: false
    end
    validate_foreign_key :certification_ship_reviews, :post_ship_events
  end
end
