# frozen_string_literal: true

require 'typesensual/schema'

class Typesensual
  # Represents a collection in Typesense, though is actually secretly an alias to a collection. This
  # allows us to create a new collection, index it, and then switch the alias to the new collection
  # seamlessly, without causing any downtime.
  class Collection
    # Set the alias name for the collection
    #
    # @param value [String] the alias name
    def self.alias_name(value)
      @alias_name = value
    end

    # Define the schema for the collection
    #
    # See {Typesensual::Schema} for more information
    def self.schema(&block)
      @schema = Typesensual::Schema.new(&block)
    end

    # Generate a new collection name for the given timestamp
    #
    # @param timestamp [Time] the timestamp to generate the collection name for
    # @return [String] the generated collection name
    def self.collection_name_for(timestamp:)
      [
        @alias_name,
        (":#{Typesensual.config.env}" if Typesensual.config.env),
        "@#{timestamp.strftime('%s')}"
      ].join
    end

    # Get the collections that match the alias name
    #
    # @return [Array<Hash>] the collections that match the alias name
    #   * `:name` [String] the alias name of the collection
    #   * `:env` [String] the environment of the collection
    #   * `:timestamp` [Time] the timestamp of the collection
    #   * `:collection` [Typesense::Collection] the Typesense collection
    def self.collections
      Typesensual.collections.filter do |collection|
        collection[:name] == @alias_name
      end
    end

    # Create a new collection with the given timestamp
    #
    # @param timestamp [Time] the timestamp to create the collection with
    # @return [String] the name of the created collection
    def self.create!(timestamp: Time.now)
      generated_name = collection_name_for(timestamp: timestamp)

      Typesensual.client.collections.create(
        @schema.to_h.merge(name: generated_name)
      )

      generated_name
    end

    # Updates the alias to point to the given collection name
    #
    # @param name [String] the name of the collection to point the alias to
    def self.update_alias!(name)
      Typesensual.client.aliases.upsert(@alias_name, collection_name: name)
    end
  end
end
