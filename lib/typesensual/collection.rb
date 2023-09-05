# frozen_string_literal: true

require 'typesensual/schema'
require 'typesensual/state_helpers'
require 'typesensual/callbacks' if defined?(ActiveRecord)

class Typesensual
  class Collection
    include StateHelpers

    # The pattern we use for collection names, `name:env@version`, where `name`
    # is the name of the index, `env` is the environment, and `version` is the
    # timestamp of the collection's creation. If a name doesn't follow this
    # pattern, `name` collects everything.
    COLLECTION_NAME_PATTERN = /^
      (?<name>.*?)           # the name of the collection cannot include : or @
      (?::(?<env>.*?))?      # the env is optional, but also cannot include : or @
      (?:@(?<version>\d+))?  # the version is also optional but must be an integer
    $/x.freeze

    include StateHelpers

    # @overload initialize(collection)
    #   Initialize a new collection from a Typesense collection hash
    #
    #   @param collection [Hash] the Typesense collection hash
    #     * `created_at` [Integer] the timestamp of the collection's creation
    #     * `default_sorting_field` [String] the default sorting field
    #     * `enable_nested_fields` [Boolean] whether nested fields are enabled
    #     * `fields` [Array<Hash>] the fields in the collection
    #     * `name` [String] the name of the collection
    #     * `num_documents` [Integer] the number of documents in the collection
    #     * `symbols_to_index` [String] the symbols to index
    #     * `token_separators` [String] the token separators
    # @overload initialize(name)
    #   Initialize a new collection, loading info from Typesense
    #
    #   @param name [String] the name of the collection
    #   @raise [Typesense::Error::ObjectNotFound] if the collection doesn't exist
    def initialize(collection_or_name)
      @collection = if collection_or_name.is_a?(Hash)
                      collection_or_name.deep_stringify_keys
                    else
                      client.collections[collection_or_name].retrieve
                    end
    end

    # Reload the underlying collection data from Typesense
    # @return [self]
    def reload
      @collection = client.collections[name].retrieve
      self
    end

    # The time the collection was created, as tracked by Typesense
    # @return [Time] the time the collection was created
    def created_at
      @created_at ||= Time.strptime(@collection['created_at'].to_s, '%s')
    end

    # The default sorting field for the collection
    # @return [String] the default sorting field
    def default_sorting_field
      @collection['default_sorting_field']
    end

    # Whether the collection has nested fields enabled
    # @return [Boolean] whether nested fields are enabled
    def enable_nested_fields?
      @collection['enable_nested_fields']
    end

    # The fields in the collection
    # @return [Array<Field>] the field information
    def fields
      @collection['fields'].map do |field|
        Field.new(field)
      end
    end

    # The raw, underlying name of the collection
    # @return [String] the name of the collection
    def name
      @collection['name']
    end

    # The number of documents in the collection
    # @return [Integer] the number of documents in the collection
    def num_documents
      @collection['num_documents']
    end

    # Special characters in strings which should be indexed as text
    # @return [Array<String>] the symbols to index
    def symbols_to_index
      @collection['symbols_to_index']
    end

    # Additional characters to be treated as separators when indexing text
    # @return [Array<String>] the token separators
    def token_separators
      @collection['token_separators']
    end

    # The name of the index, parsed from the Typesensual collection naming scheme.
    # @see COLLECTION_NAME_PATTERN
    # @return [String] the name of the index
    def index_name
      parsed_name['name']
    end

    # The environment the collection is in, parsed from the Typesensual collection
    # naming scheme.
    # @see COLLECTION_NAME_PATTERN
    # @return [String] the environment the collection is in
    def env
      parsed_name['env']
    end

    # The version of the collection, parsed from the Typesensual collection naming
    # scheme.
    # @see COLLECTION_NAME_PATTERN
    # @return [String] the version of the collection
    def version
      parsed_name['version']
    end

    # Creates the collection in Typesense
    # @return [self]
    def create!
      client.collections.create(@collection)
      self
    end

    # Deletes the collection in Typesense
    # @return [void]
    def delete!
      typesense_collection.delete
    end

    # Create a new collection using the given collection hash
    #
    # @param collection [Hash] the Typesense collection hash
    #   * `default_sorting_field` [String] the default sorting field
    #   * `enable_nested_fields` [Boolean] whether nested fields are enabled
    #   * `fields` [Array<Hash>] the fields in the collection
    #   * `name` [String] the name of the collection
    #   * `symbols_to_index` [String] the symbols to index
    #   * `token_separators` [String] the token separators
    # @return [Collection] the created collection
    def self.create!(collection)
      new(collection).tap(&:create!)
    end

    # Insert a single document into typesense
    #
    # @param doc [Hash] the document to insert
    # @return [Boolean] if the document was inserted successfully
    def insert_one!(doc)
      typesense_collection.documents.upsert(doc)
    end

    # Insert many documents into typesense. Notably, the input can be an enumerable
    # or enumerator, which will be batched into groups of `batch_size` and inserted
    # with the ID of any failed rows being provided in the response.
    #
    # @param docs [Enumerable<Hash>] the documents to insert
    # @return [Array<Hash>] any failed insertions
    def insert_many!(docs, batch_size: 100)
      docs.lazy.each_slice(batch_size).with_object([]) do |slice, failures|
        results = typesense_collection.documents.import(slice, return_id: true, action: 'upsert')
        failures.push(*results.reject { |result| result['success'] })
      end
    end

    # Remove a single document from typesense
    #
    # @param id [String] the ID of the document to remove
    # @return [void]
    def remove_one!(id)
      typesense_collection.documents[id.to_s].delete
    end

    # Remove multiple documents from typesense based on a filter
    #
    # @param filter_by [String] the filter to use to remove documents
    # @return [void]
    def remove_many!(filter_by:)
      typesense_collection.documents.delete(filter_by: filter_by)
    end

    # Search for documents in typesense
    #
    # @param query [String] the query to search for
    # @param query_by [String] the fields to search by
    # @return [Search] the search object
    def search(query:, query_by:)
      Search.new(
        collection: self,
        query: query,
        query_by: query_by
      )
    end

    def typesense_collection
      @typesense_collection ||= client.collections[name]
    end

    private

    def parsed_name
      @parsed_name ||= name.match(COLLECTION_NAME_PATTERN)
    end
  end
end
