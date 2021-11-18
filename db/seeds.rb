# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

3000.times do |schema|
  ActiveRecord::Base.connection.schema_search_path = "\"#{"schema-#{schema + 1}"}\", \"$user\", public"
  print "."

  # if User.count == 0
  #   [].tap do |array|
  #     100.times do |index|
  #       time = Time.current
  #       array << {
  #         name: Faker::Name.name,
  #         email: Faker::Internet.email,
  #         admin: false,
  #         created_at: time,
  #         updated_at: time
  #       }
  #     end

  #     User.insert_all(array)
  #   end
  # end

  # if Contact.count == 0
  #   [].tap do |array|
  #     100.times do |index|
  #       time = Time.current
  #       array << {
  #         first_name: Faker::Name.first_name,
  #         last_name: Faker::Name.last_name,
  #         email: Faker::Internet.email,
  #         telephone: Faker::PhoneNumber.phone_number,
  #         created_at: time,
  #         updated_at: time
  #       }
  #     end

  #     Contact.insert_all(array)
  #   end
  # end

  # if Product.count == 0
  #   [].tap do |array|
  #     100.times do |index|
  #       time = Time.current
  #       array << {
  #         name: Faker::Commerce.product_name,
  #         sku: "SKU-#{index + 1}",
  #         created_at: time,
  #         updated_at: time
  #       }
  #     end

  #     Product.insert_all(array)
  #   end
  # end

  # if Order.count == 0
  #   [].tap do |array|
  #     100.times do |index|
  #       time = Time.current
  #       array << {
  #         number: "ON-#{index + 1}",
  #         reference: Faker::Commerce.product_name,
  #         user_id: Random.rand(1...100),
  #         contact_id: Random.rand(1...100),
  #         ordered_at: Faker::Time.forward(days: 23, period: :morning),
  #         delivery_at: Faker::Time.forward(days: 23, period: :morning),
  #         created_at: time,
  #         updated_at: time
  #       }
  #     end

  #     Order.insert_all(array)
  #   end

  #   [].tap do |array|
  #     300.times do |index|
  #       time = Time.current
  #       array << {
  #         order_id: Random.rand(1...100),
  #         product_id: Random.rand(1...100),
  #         quantity: Random.rand(1...100),
  #         price: Faker::Commerce.price,
  #         created_at: time,
  #         updated_at: time
  #       }
  #     end

  #     OrderItem.insert_all(array)
  #   end
  # end
end
