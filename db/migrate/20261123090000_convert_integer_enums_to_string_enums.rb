class ConvertIntegerEnumsToStringEnums < ActiveRecord::Migration[8.1]
  # table => { column => { integer_value => "string_value" } }
  # Integer values mirror the old integer enum definitions in the models,
  # so existing rows keep the same meaning after conversion.
  ENUM_MAPPINGS = {
    users: {
      role: { 0 => "customer", 1 => "partner", 2 => "admin" }
    },
    partners: {
      status: { 0 => "active", 1 => "inactive" }
    },
    service_categories: {
      category_name: { 0 => "cook", 1 => "maid", 2 => "electrician", 3 => "plumber", 4 => "painter" }
    },
    booking_search_rounds: {
      status: { 0 => "searching", 1 => "completed", 2 => "stopped", 3 => "expired" }
    },
    bookings: {
      status: {
        0 => "pending_admin_review",
        1 => "searching_partner",
        2 => "awaiting_customer_decision",
        3 => "awaiting_partner_response",
        4 => "confirmed",
        5 => "in_progress",
        6 => "completed",
        7 => "expired",
        8 => "cancelled",
        9 => "partner_not_available"
      },
      assignment_mode: { 0 => "manual", 1 => "broadcast" },
      customer_search_decision: { 0 => "pending", 1 => "wait", 2 => "cancel", 3 => "expired" }
    },
    booking_offers: {
      response: { 0 => "pending", 1 => "accepted", 2 => "rejected", 3 => "expired", 4 => "closed" },
      source: { 0 => "manual", 1 => "broadcast" }
    }
  }.freeze

  def up
    ENUM_MAPPINGS.each do |table, columns|
      columns.each do |column, mapping|
        cases = mapping.map { |int, str| "WHEN #{int} THEN #{quote(str)}" }.join(" ")
        execute <<~SQL
          ALTER TABLE #{connection.quote_table_name(table)}
          ALTER COLUMN #{connection.quote_column_name(column)} TYPE varchar
          USING (CASE #{connection.quote_column_name(column)} #{cases} ELSE NULL END)
        SQL
      end
    end
  end

  def down
    ENUM_MAPPINGS.each do |table, columns|
      columns.each do |column, mapping|
        cases = mapping.map { |int, str| "WHEN #{quote(str)} THEN #{int}" }.join(" ")
        execute <<~SQL
          ALTER TABLE #{connection.quote_table_name(table)}
          ALTER COLUMN #{connection.quote_column_name(column)} TYPE integer
          USING (CASE #{connection.quote_column_name(column)} #{cases} ELSE NULL END)
        SQL
      end
    end
  end

  private

  def quote(value)
    connection.quote(value)
  end
end
