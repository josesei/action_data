Gem::Specification.new do |spec|
  spec.name          = "action_data"
  spec.version       = "0.0.0"
  spec.authors       = ["Jose Ignacio Carbone"]
  spec.email         = []

  spec.summary       = "A tool to build and query joinable ActiveRecord models"
  spec.description   = "Base provides a flexible way to define joinable ActiveRecord models and dynamically build SQL queries with aggregation, grouping, and custom fields."
  spec.homepage      = "https://github.com/josesei/action_data"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "README.md"]
  spec.required_ruby_version = ">= 2.5.0"

  spec.add_dependency "activerecord", ">= 5.0"

  spec.add_development_dependency "rspec", "~> 3.10"
  spec.add_development_dependency "sqlite3"
end
