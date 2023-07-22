# frozen_string_literal: true

class Typesensual
  class Callbacks
    def initialize(index, should_update: ->(_record) { true })
      @index = index
      @should_update = should_update
    end

    def after_create_commit(record)
      @index.index_one(record.id)
    end

    def after_update_commit(record)
      @should_update.call(record) && @index.index_one(record.id)
    end

    def after_destroy_commit(record)
      @index.remove_one(record.id)
    end
  end
end
