# frozen_string_literal: true

class Typesensual
  class Search
    # Represents a facet returned with search results
    class Facet
      attr_reader :key

      def initialize(key, facet)
        @key = key
        @facet = facet
      end

      def count
        @facet['count']
      end

      def value
        @facet['value']
      end

      def highlighted
        @facet['highlighted']
      end
    end
  end
end
