# frozen_string_literal: true

require 'bundler/setup'
require 'simplecov'

SimpleCov.start

require 'typesensual'

Typesensual.configure do |config|
  config.nodes = [{ host: 'localhost', port: 8108, protocol: 'http' }]
  config.api_key = 'xyz'
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Nuke the data after each test
  config.after do
    Typesensual.client.collections.retrieve.each do |c|
      Typesensual.client.collections[c['name']].delete
    end

    Typesensual.client.aliases.retrieve['aliases'].each do |a|
      Typesensual.client.aliases[a['name']].delete
    end
  end
end
