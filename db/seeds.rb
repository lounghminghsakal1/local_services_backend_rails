# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


puts "Seeding database..."


# 1. Admin
admin_user = User.find_or_create_by!(email: "admin@example.com") do |u|
  u.name = "System Admin"
  u.password_hash = "hashed_password_123"
  u.role = :admin
end
admin = Admin.find_or_create_by!(user: admin_user)

# 2. Customer + Address (required for creating a booking)
customer_user = User.find_or_create_by!(email: "customer@example.com") do |u|
  u.name = "Rahul Sharma"
  u.password_hash = "hashed_password_123"
  u.role = :customer
end
customer = Customer.find_or_create_by!(user: customer_user)

address = Address.find_or_create_by!(user: customer_user, is_default: true) do |a|
  a.door_no = "402"
  a.street = "Jubilee Hills Road No 36"
  a.address_line = "Plot 12, Near Metro Station"
  a.city = "Hyderabad"
  a.state = "Telangana"
  a.country = "India"
end

# 3. Partners (creating 2 so you can test offer rejection / reassignment)
partner_user_1 = User.find_or_create_by!(email: "partner1@example.com") do |u|
  u.name = "Ravi Kumar"
  u.password_hash = "hashed_password_123"
  u.role = :partner
end
partner_1 = Partner.find_or_create_by!(user: partner_user_1) do |p|
  p.current_lat = "17.43"
  p.current_long = 78.41 # fits precision: 4, scale: 2
  p.location_updated_at = Time.current
  p.status = :active
end

partner_user_2 = User.find_or_create_by!(email: "partner2@example.com") do |u|
  u.name = "Suresh Reddy"
  u.password_hash = "hashed_password_123"
  u.role = :partner
end
partner_2 = Partner.find_or_create_by!(user: partner_user_2) do |p|
  p.current_lat = "17.45"
  p.current_long = 78.39
  p.location_updated_at = Time.current
  p.status = :active
end

# 4. Service Categories
plumbing = ServiceCategory.find_or_create_by!(category_name: :plumber) do |sc|
  sc.description = "Plumbing and pipe repair"
  sc.min_price = 299.00
end

electrical = ServiceCategory.find_or_create_by!(category_name: :electrician) do |sc|
  sc.description = "Electrical wiring and appliance fixes"
  sc.min_price = 349.00
end

# 5. Partner Services
PartnerService.find_or_create_by!(partner: partner_1, service_category: plumbing) do |ps|
  ps.experience = "5 years"
  ps.is_active = true
end

PartnerService.find_or_create_by!(partner: partner_2, service_category: plumbing) do |ps|
  ps.experience = "3 years"
  ps.is_active = true
end

PartnerService.find_or_create_by!(partner: partner_2, service_category: electrical) do |ps|
  ps.experience = "4 years"
  ps.is_active = true
end

puts <<~SUMMARY
  Seeding complete! Use these IDs for your API requests:
  ------------------------------------------------------
  Admin ID:            #{admin.id}
  Customer ID:         #{customer.id}
  Address ID:          #{address.id}
  Partner 1 ID:        #{partner_1.id} (Plumbing)
  Partner 2 ID:        #{partner_2.id} (Plumbing, Electrical)
  Plumbing Cat ID:     #{plumbing.id}
  Electrical Cat ID:   #{electrical.id}
SUMMARY
