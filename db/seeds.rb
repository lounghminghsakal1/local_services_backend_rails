# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# What this seeds (all in Hyderabad):
#   * 5 service categories
#   * 2 admins, 10 customers, 50 partners   -> every account's password is  <Name>@123  (Sakal -> Sakal@123)
#   * 50 distinct locations: each partner lives at one location; the 10 customers' addresses sit on every 5th
#     location, so they are spread across the whole city and radius searches (10 / 20 / 50 km) have something to find.
# Test accounts:  customer Sakal, partner Leo (offers all 5 services), admin Mingh.

puts "Seeding database..."

# ---------------------------------------------------------------------------
# Data
# ---------------------------------------------------------------------------

# 50 distinct Hyderabad localities with APPROXIMATE coordinates: [name, latitude, longitude]
PLACES = [
  [ "Banjara Hills", 17.4126, 78.4482 ], [ "Jubilee Hills", 17.4326, 78.4071 ], [ "Madhapur", 17.4486, 78.3908 ],
  [ "Gachibowli", 17.4401, 78.3489 ], [ "Kondapur", 17.4635, 78.3638 ], [ "HITEC City", 17.4435, 78.3772 ],
  [ "Secunderabad", 17.4399, 78.4983 ], [ "Begumpet", 17.4440, 78.4676 ], [ "Ameerpet", 17.4375, 78.4483 ],
  [ "Kukatpally", 17.4948, 78.3996 ], [ "Miyapur", 17.4968, 78.3614 ], [ "Uppal", 17.4058, 78.5591 ],
  [ "LB Nagar", 17.3457, 78.5522 ], [ "Dilsukhnagar", 17.3688, 78.5247 ], [ "Charminar", 17.3616, 78.4747 ],
  [ "Mehdipatnam", 17.3950, 78.4350 ], [ "Tolichowki", 17.4062, 78.4090 ], [ "Manikonda", 17.4034, 78.3871 ],
  [ "Narsingi", 17.3910, 78.3590 ], [ "Financial District", 17.4170, 78.3430 ], [ "Kompally", 17.5350, 78.4860 ],
  [ "Alwal", 17.5030, 78.5120 ], [ "Bowenpally", 17.4700, 78.4750 ], [ "Sanathnagar", 17.4570, 78.4440 ],
  [ "Yousufguda", 17.4330, 78.4230 ], [ "SR Nagar", 17.4430, 78.4400 ], [ "Erragadda", 17.4580, 78.4350 ],
  [ "Moosapet", 17.4750, 78.4300 ], [ "Balanagar", 17.4700, 78.4400 ], [ "Nizampet", 17.5150, 78.3850 ],
  [ "Bachupally", 17.5400, 78.3600 ], [ "Chandanagar", 17.4940, 78.3270 ], [ "Lingampally", 17.4930, 78.3180 ],
  [ "Attapur", 17.3680, 78.4230 ], [ "Rajendranagar", 17.3220, 78.4000 ], [ "Nagole", 17.3760, 78.5560 ],
  [ "Habsiguda", 17.4170, 78.5450 ], [ "Tarnaka", 17.4270, 78.5340 ], [ "Malkajgiri", 17.4540, 78.5270 ],
  [ "Sainikpuri", 17.4850, 78.5480 ], [ "ECIL", 17.4700, 78.5700 ], [ "Kothapet", 17.3650, 78.5400 ],
  [ "Saidabad", 17.3550, 78.5080 ], [ "Santoshnagar", 17.3550, 78.4900 ], [ "Bahadurpura", 17.3450, 78.4500 ],
  [ "Golconda", 17.3833, 78.4011 ], [ "Nampally", 17.3920, 78.4690 ], [ "Abids", 17.3910, 78.4750 ],
  [ "Panjagutta", 17.4270, 78.4510 ], [ "Somajiguda", 17.4250, 78.4600 ]
].freeze

ADMIN_NAMES = %w[Mingh Kavya].freeze

CUSTOMER_NAMES = %w[Sakal Anjali Divya Meena Neha Pooja Priya Radhika Sneha Swathi].freeze

PARTNER_NAMES = %w[
  Leo Ravi Suresh Venkat Srinivas Ramesh Naresh Mahesh Ganesh Rajesh
  Anil Sunil Kiran Praveen Vijay Ajay Sanjay Manoj Satish Harish
  Girish Nagaraj Prakash Krishna Mohan Rohit Arun Varun Tarun Karthik
  Bharath Chandra Dinesh Eswar Faisal Hari Imran Jagan Lokesh Murali
  Naveen Omkar Pavan Raghu Sai Teja Uday Vamsi Yash Zaheer
].freeze

# category_name => [description, min_price]
CATEGORIES = {
  cook: [ "Home cooking and meal preparation", 249.00 ],
  maid: [ "House cleaning and maid services", 199.00 ],
  electrician: [ "Electrical wiring and appliance fixes", 349.00 ],
  plumber: [ "Plumbing and pipe repair", 299.00 ],
  painter: [ "Interior and exterior painting", 399.00 ]
}.freeze

# Guard rails: fail loudly (before touching the database) if the lists above are edited wrongly.
all_names = ADMIN_NAMES + CUSTOMER_NAMES + PARTNER_NAMES
raise "PLACES must hold 50 distinct locations" unless PLACES.size == 50 && PLACES.map { |_, lat, lng| [ lat, lng ] }.uniq.size == 50
raise "Need exactly 50 partner names" unless PARTNER_NAMES.size == 50
raise "Need exactly 10 customer names" unless CUSTOMER_NAMES.size == 10
raise "Need exactly 2 admin names" unless ADMIN_NAMES.size == 2
raise "Names must be unique across all roles (the email is built from the name)" unless all_names.map(&:downcase).uniq.size == all_names.size

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Idempotent AND self-repairing: running the seeds again also fixes rows created earlier.
# Email: <name>@example.com    Password: <Name>@123
#
# "Leo@123" and "Sai@123" are 7 characters, below the 8-character minimum the User model enforces
# on signup. The seeds skip ONLY that one rule so the requested test passwords work; every other
# validation (email format, uniqueness, presence ...) still applies.
def seed_user!(name:, role:)
  user = User.find_or_initialize_by(email: "#{name.downcase}@example.com")
  user.assign_attributes(name: name, password: "#{name}@123", role: role)

  user.validate
  blocking_errors = user.errors.reject { |error| error.attribute == :password && error.type == :too_short }
  raise ActiveRecord::RecordInvalid, user if blocking_errors.any?

  user.save!(validate: false)
  user
end

def seed_address!(user:, place_index:, label:)
  place_name, latitude, longitude = PLACES.fetch(place_index)

  address = Address.find_or_initialize_by(user: user, is_default: true)
  address.assign_attributes(
    door_no: (100 + place_index).to_s,
    street: "#{place_name} Main Road",
    address_line: "#{label}, #{place_name}",
    city: "Hyderabad",
    state: "Telangana",
    country: "India",
    latitude: latitude,
    longitude: longitude
  )
  address.save!
  address
end

# ---------------------------------------------------------------------------
# Seeding (one transaction: either everything is created or nothing is)
# ---------------------------------------------------------------------------

ActiveRecord::Base.transaction do
  # 1. Service categories
  categories = CATEGORIES.to_h do |category_name, (description, min_price)|
    category = ServiceCategory.find_or_initialize_by(category_name: category_name.to_s)
    category.assign_attributes(description: description, min_price: min_price)
    category.save!
    [ category_name, category ]
  end

  # 2. Admins
  ADMIN_NAMES.each do |name|
    Admin.find_or_create_by!(user: seed_user!(name: name, role: :admin))
  end

  # 3. Customers: every 5th location, so the 10 customers are spread over all 50
  CUSTOMER_NAMES.each_with_index do |name, index|
    user = seed_user!(name: name, role: :customer)
    Customer.find_or_create_by!(user: user)
    seed_address!(user: user, place_index: index * 5, label: "Flat #{101 + index}")
  end

  # 4. Partners: partner N lives (and is currently located) at location N
  PARTNER_NAMES.each_with_index do |name, index|
    _place_name, latitude, longitude = PLACES.fetch(index)

    user = seed_user!(name: name, role: :partner)
    residential_address = seed_address!(user: user, place_index: index, label: "Plot #{201 + index}")

    partner = Partner.find_or_initialize_by(user: user)
    partner.assign_attributes(
      current_lat: latitude,
      current_long: longitude,
      location_updated_at: Time.current, # fresh, so the live location (not the home address) is used for distance
      status: "active",
      residential_address: residential_address
    )
    partner.save!

    # Leo (the test partner) offers every service; everybody else offers 2 of the 5
    service_names = index.zero? ? CATEGORIES.keys : [ CATEGORIES.keys[index % 5], CATEGORIES.keys[(index + 2) % 5] ]
    service_names.each do |service_name|
      partner_service = PartnerService.find_or_initialize_by(partner: partner, service_category: categories.fetch(service_name))
      partner_service.assign_attributes(experience: "#{2 + index % 9} years", is_active: true)
      partner_service.save!
    end
  end
end

puts <<~SUMMARY
  Seeding complete!
    admins:    #{Admin.joins(:user).where(users: { email: ADMIN_NAMES.map { |n| "#{n.downcase}@example.com" } }).count}
    customers: #{Customer.joins(:user).where(users: { email: CUSTOMER_NAMES.map { |n| "#{n.downcase}@example.com" } }).count}
    partners:  #{Partner.joins(:user).where(users: { email: PARTNER_NAMES.map { |n| "#{n.downcase}@example.com" } }).count}
    categories: #{ServiceCategory.count}

  Every account:  email <name>@example.com   password <Name>@123
  Test accounts:
    customer  sakal@example.com   Sakal@123   POST /api/v1/customer/login
    partner   leo@example.com     Leo@123     POST /api/v1/partner/login
    admin     mingh@example.com   Mingh@123   POST /api/v1/admin/login
  Each login returns a token; send it as  Authorization: Bearer <token>
SUMMARY
