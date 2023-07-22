# frozen_string_literal: true

class Typesensual
  class Search
    class Results
      def initialize(results)
        @results = results
      end

      def hits
        @results['hits'].map { |hit| Hit.new(hit) }
      end

      def count
        @results['found']
      end

      def out_of
        @results['out_of']
      end

      def current_page
        @results['page']
      end

      def first_page?
        current_page == 1
      end

      def last_page?
        current_page == total_pages
      end

      def prev_page
        current_page - 1 unless first_page?
      end

      def next_page
        current_page + 1 unless last_page?
      end

      def search_time_ms
        @results['search_time_ms']
      end

      def total_pages
        (@results['found'] / @results['per_page'].to_f).ceil
      end
    end
  end
end
