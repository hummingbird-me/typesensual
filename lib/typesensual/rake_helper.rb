# frozen_string_literal: true

require 'paint'

class Typesensual
  class RakeHelper
    HEADER_FORMAT = Paint["==> %s\n", :bold]
    LIST_ROW_FORMAT = "%<prefix>4s %<version>-20s %<created_at>-20s %<documents>-20s\n"
    LIST_HEADER = Paint[format(
      LIST_ROW_FORMAT,
      prefix: '', version: 'Version', created_at: 'Created At', documents: 'Documents'
    ), :bold, :underline]

    class << self
      # List the collections in all Index descendants
      #
      # @param output [IO] The output stream to write to
      # @example
      #   rake typesensual:list
      def list(output: $stdout)
        # Build up a hash of indices and their (sorted) collections
        indices = Index.descendants.to_h do |index|
          [index, index.collections.sort_by(&:created_at).reverse]
        end

        indices.each do |index, collections|
          alias_name = index.collection.name

          output.printf(HEADER_FORMAT, index.name.titleize)
          output.printf(LIST_HEADER)

          collections.each do |collection|
            output.printf(LIST_ROW_FORMAT,
              prefix: collection.name == alias_name ? '->' : '',
              version: collection.version,
              created_at: collection.created_at.strftime('%Y-%m-%d %H:%M:%S'),
              documents: collection.num_documents)
          end

          output.printf("\n")
        end
      end

      # Index all records from a model into an index
      #
      # @param index [String] The name of the index to index into
      # @param model [String] The name of the model to index from
      # @example
      #   rake typesensual:index[FooIndex,Foo]
      def index(index:, model:, output: $stdout)
        index = index.safe_constantize
        model = model.safe_constantize

        collection = index.create!
        output.printf(
          Paint["==> Indexing %<model>s into %<index>s (Version %<version>s)\n", :bold],
          model: model.name,
          index: index.name,
          version: collection.version
        )
        failures = index.index_many(
          model.ids,
          collection: collection
        )

        failures.each do |failure|
          output.puts(failure.to_json)
        end
      end

      # Update the alias for an index to point to a specific version
      #
      # @param index [String] The name of the index to update
      # @param version [String] The version to update the alias to
      # @example
      #   rake typesensual:update_alias[FooIndex,1]
      def update_alias(index:, version:, output: $stdout)
        index = index.safe_constantize
        old_coll = index.collection
        new_coll = index.collection_for(version: version)

        unless new_coll
          output.puts(Paint["--> No such version #{version} for #{index.name}", :bold])
          return
        end

        output.puts(Paint["==> Alias for #{index.name}", :bold])
        output.printf(
          "Old: %<version>s (%<created_at>s)\n",
          version: old_coll&.version || 'None',
          created_at: old_coll&.created_at&.strftime('%Y-%m-%d %H:%M:%S') || 'N/A'
        )
        index.update_alias!(new_coll)

        output.printf(
          "New: %<version>s (%<created_at>s)\n",
          version: new_coll.version,
          created_at: new_coll.created_at.strftime('%Y-%m-%d %H:%M:%S')
        )
      end
    end
  end
end
