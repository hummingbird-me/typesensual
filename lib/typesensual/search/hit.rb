# frozen_string_literal: true

class Typesensual
  class Search
    class Hit
      # {
      #   "highlights": [
      #     {
      #       "field": "company_name",
      #       "matched_tokens": ["Stark"],
      #       "snippet": "<mark>Stark</mark> Industries"
      #     }
      #   ],
      #   "document": {
      #     "id": "124",
      #     "company_name": "Stark Industries",
      #     "num_employees": 5215,
      #     "country": "USA"
      #   },
      #   "text_match": 130916
      # }
      # @param hit [Hash] the Typesense hit hash
      #   * `highlights` [Array<Hash>] the highlights for the hit
      #   * `document` [Hash] the matching document
      #   * `text_match` [Integer] the text matching score
      def initialize(hit)
        @hit = hit
      end

      def highlights
        @hit['highlights']
      end

      def document
        @hit['document']
      end

      def score
        @hit['text_match']
      end
    end
  end
end
