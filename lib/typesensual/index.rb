# frozen_string_literal: true

require 'typesensual/schema'
require 'typesensual/state_helpers'

class Typesensual
  # Represents your index as a set of collections in Typesense. Manages
  # Typesense aliases, but with some extra functionality for managing multiple
  # environments and versions, and a nice DSL for defining your schema.
  #
  # @example Defining an index
  #   class PostsIndex < Typesensual::Index
  #     # Optional, default is inferred from the class name
  #     index_name 'user_posts'
  #
  #     schema do
  #       field 'text', type: 'string[]'
  #       field 'user', type: 'string', facet: true
  #     end
  #   end
  class Index
    include StateHelpers

    class << self
      delegate :search, to: :collection
    end

    def self.inherited(subclass)
      super
      # Copy the schema from the parent class to the subclass
      subclass.instance_variable_set(:@schema, @schema&.dup)
    end

    # Get or set the name for this index
    #
    # @overload index_name(value)
    #   Explicitly set the index name
    #
    #   @param value [String] the name to identify this index
    #   @return [void]
    #
    # @overload index_name
    #   Get the index name (either explicitly set or inferred from the class name)
    #
    #   @return [String] the name of this index
    def self.index_name(value = nil)
      if value
        @index_name = value
      else
        @index_name ||= name.underscore.sub(/_index$/, '')
      end
    end

    # The alias name for this index in the current environment
    #
    # @return [String] the alias name
    def self.alias_name
      [index_name, env].compact.join(':')
    end

    # Generate a new collection name for the given version
    #
    # @param version [String] the version to generate the collection name for
    # @return [String] the generated collection name
    def self.collection_name_for(version: Time.now.strftime('%s'))
      "#{alias_name}@#{version}"
    end

    # Create a new collection for this index
    #
    # @param version [String] the version to create the collection for
    # @return [Collection] the newly created collection
    def self.create!(version: Time.now.strftime('%s'))
      generated_name = collection_name_for(version: version)

      Collection.create!(@schema.to_h.merge('name' => generated_name))
    end

    # Get the collections for this index
    #
    # @return [Array<Collection>] the collections that match the alias
    def self.collections
      Typesensual.collections.filter do |collection|
        collection.index_name == index_name
      end
    end

    def self.collection_for(version:)
      Typesensual.collections.find do |collection|
        collection.version == version
      end
    end

    # Get the collection that the alias points to
    #
    # @return [Collection] the collection that the alias points to
    def self.collection
      @collection ||= Collection.new(alias_name)
    rescue Typesense::Error::ObjectNotFound
      nil
    end

    # Define the schema for the collection
    #
    # See {Schema} for more information
    def self.schema(&block)
      @schema ||= Typesensual::Schema.new
      @schema.instance_eval(&block) if block
      @schema
    end

    # Updates the alias to point to the given collection name
    #
    # @param name [String, Collection] the collection to point the alias to
    def self.update_alias!(name_or_collection)
      name = if name_or_collection.is_a?(Collection)
               name_or_collection.name
             else
               name_or_collection
             end

      client.aliases.upsert(alias_name, collection_name: name)
    end

    # Indexes the given records into a collection, then updates the alias to
    # point to it.
    #
    # @param records [Enumerable] the records to index
    # @param collection [Collection] the collection to index into, defaults to a
    #   new collection
    def self.reindex!(ids, collection: create!)
      index_many(ids, collection: collection)

      update_alias!(collection)
    end

    def self.index_one(id, collection: self.collection)
      new.index([id]) do |record|
        collection.insert_one!(record)
      end
    end

    # The method to implement to index *many* records
    # This method should yield successive records to index
    #
    # @yield [Hash] a document to upsert in Typesense
    def index(ids)
      ids.each do |id|
        yield({ id: id })
      end
    end

    def self.index_many(ids, collection: self.collection, batch_size: 100)
      collection.insert_many!(
        new.enum_for(:index, ids),
        batch_size: batch_size
      )
    end

    def self.remove_one(id, collection: self.collection)
      collection.remove_one!(id)
    end

    if defined?(ActiveRecord)
      def self.ar_callbacks
        Typesensual::Callbacks.new(self)
      end
    end
  end
end
