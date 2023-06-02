# frozen_string_literal: true

require 'typesense'

require 'typesensual/version'
require 'typesensual/config'
require 'typesensual/collection'

class Typesensual
  COLLECTION_NAME_PATTERN = /^
    (?<name>.*?)        # the name of the collection cannot include : or @
    (?::(?<env>.*?))?   # the env is optional, but also cannot include : or @
    (?:@(?<ts>\d+))?    # the timestamp is also optional but must be an integer
  $/x.freeze

  class << self
    attr_accessor :config

    def client
      config.client
    end

    def configure(&block)
      self.config = Typesensual::Config.new(&block)
    end

    # Get the collections that match the alias name
    #
    # @return [Array<Hash>] the collections that match the alias name
    #   * `:name` [String] the name of the collection
    #   * `:env` [String] the environment of the collection
    #   * `:timestamp` [Time] the timestamp of the collection
    #   * `:collection` [Typesense::Collection] the Typesense collection
    def collections
      Typesensual.client.collections.retrieve.filter_map do |collection|
        matches = collection['name'].match(COLLECTION_NAME_PATTERN)

        # Deal with invalid timestamps by just setting it to nil
        timestamp = begin
          Time.strptime(matches['ts'], '%s')
        rescue ArgumentError, TypeError
          nil
        end

        {
          collection: Typesensual.client.collections[collection['name']],
          name: matches['name'],
          env: matches['env'],
          timestamp: timestamp
        }
      end
    end
  end
end
