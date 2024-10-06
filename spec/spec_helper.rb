# spec/spec_helper.rb
require "bundler/setup"
require "action_data"
require "active_record"

# Establish connection to an in-memory SQLite3 database
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

ActiveRecord::Schema.define do
  create_table :orders, force: true do |t|
    t.string :order_number
    t.integer :customer_id
    t.decimal :total_price
    t.timestamps
  end

  create_table :order_items, force: true do |t|
    t.integer :order_id
    t.decimal :weight
    t.timestamps
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
