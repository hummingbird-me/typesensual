# frozen_string_literal: true

require 'typesensual/search/hit'
require 'typesensual/search/results'

class Typesensual
  class Search
    # Initialize a new search object for a collection
    #
    # @param collection [Typesensual::Collection] the Typesensual collection object
    # @param query [String] the query string to search for
    # @param query_by [String, Symbol, Array<String, Symbol>, Hash<String, Symbol>] the fields to
    #   search in. If a hash is provided, the keys are the fields and the values are the weights.
    #   If a string is provided, it is used directly as the query_by parameter. If an array is
    #   provided, the values are the fields.
    def initialize(collection:, query:, query_by:)
      @filter_by = []
      @sort_by = []
      @facet_by = []
      @facet_query = []
      @include_fields = []
      @exclude_fields = []
      @params = {}

      @collection = collection
      @query = query

      if query_by.is_a?(Hash)
        @query_by = query_by.keys
        @query_by_weights = query_by.values
      elsif query_by.is_a?(String) || query_by.is_a?(Symbol)
        @query_by = [query_by]
      else
        @query_by = query_by
      end
    end

    # Set the number of results to return per page
    # @param count [Integer] the number of results to return per page
    def per(count)
      set(per_page: count)
    end

    # Set the page number to return
    # @param number [Integer] the page number to return
    def page(number)
      set(page: number)
    end

    # Add a filter to the search
    # @param filter [String, Symbol, Hash<String, Symbol>] the filter to add. If a hash is
    #   provided, the keys are the fields and the values are the values to filter by. If a
    #   string is provided, it is added directly as a filter. All filters are ANDed together.
    def filter(filter)
      if filter.is_a?(Hash)
        @filter_by += filter.map { |key, value| "#{key}:#{value}" }
      else
        @filter_by << filter.to_s
      end
      self
    end

    # Add a sort to the search
    # @param value [String, Symbol, Hash<String, Symbol>] the sort to add to the search. If
    #   a hash is provided, the keys are the fields and the values are the directions to sort.
    #   If a string is provided, it is added directly as a sort.
    def sort(value)
      if value.is_a?(Hash)
        @sort_by += value.map { |key, direction| "#{key}:#{direction}" }
      else
        @sort_by << value.to_s
      end
      self
    end

    # Add a field to facet to the seach
    # @param facets [String, Symbol, Array<String, Symbol>, Hash<String, Symbol>] the fields to
    #   facet by. If a hash is provided, the keys are the fields and the values are strings to
    #   query each facet. If an Array is provided, the values are fields to facet by. If a string
    #   is provided, it is added directly as a facet.
    def facet(facets)
      if facets.is_a?(Hash)
        facets.each do |key, value|
          @facet_by << key.to_s
          @facet_query << "#{key}:#{value}" if value
        end
      elsif facets.is_a?(Array)
        @facet_by += facets.map(&:to_s)
      else
        @facet_by << facets.to_s
      end
      self
    end

    # Add fields to include in the search result documents
    # @param fields [String, Symbol, Array<String, Symbol>] the fields to include
    def include_fields(*fields)
      @include_fields += fields.map(&:to_s)
      self
    end

    # Add fields to exclude from the search result documents
    # @param fields [String, Symbol, Array<String, Symbol>] the fields to exclude
    def exclude_fields(*fields)
      @exclude_fields += fields.map(&:to_s)
      self
    end

    # Set additional parameters to pass to the search
    # @param values [Hash] the parameters to set
    def set(values)
      @params.merge!(values)
      self
    end

    # Generate the query document
    def query
      {
        collection: @collection.name,
        filter_by: @filter_by.join(' && '),
        q: @query,
        query_by: @query_by&.join(','),
        query_by_weights: @query_by_weights&.join(','),
        sort_by: @sort_by&.join(','),
        facet_by: @facet_by&.join(','),
        facet_query: @facet_query&.join(','),
        include_fields: @include_fields&.join(','),
        exclude_fields: @exclude_fields&.join(',')
      }.merge(@params).reject { |_, v| v.blank? }
    end

    # Load the results from the search query
    def load
      Results.new(@collection.typesense_collection.documents.search(query))
    end
  end
end
