class RemoveDefaultLatLongFromAddresses < ActiveRecord::Migration[8.1]
  # Every address used to silently get 17.29 / 78.29, which made all addresses look like
  # the same place and broke distance-based partner search.
  # `from:` / `to:` makes the migration reversible (rollback puts the old defaults back).
  # NOTE: the columns stay NOT NULL, so an address without coordinates is now rejected by the DB.
  # Existing rows keep their current values (removing a default never changes stored data).
  def change
    change_column_default :addresses, :latitude, from: 17.29, to: nil
    change_column_default :addresses, :longitude, from: 78.29, to: nil
  end
end
