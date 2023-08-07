# frozen_string_literal: true

class Typesensual
  class Search
    class GroupedHit
      # {
      #   "group_key": [
      #     "420",
      #     "69"
      #   ],
      #   "hits": {
      #     ...
      #   },
      #   "found": 3
      # }
      # @param group [Hash] the Typesense hit hash
      #   * `group_key` [Array<any>] the grouping keys
      #   * `hits` [Hash] the Hits for the group
      #   * `found` [Integer] the number of hits in the group
      def initialize(group)
        @group = group
      end

      def count
        @group['found']
      end

      def hits
        @group['hits'].map { |hit| Hit.new(hit) }
      end

      def group_key
        @group['group_key']
      end
    end
  end
end
