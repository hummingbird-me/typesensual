# frozen_string_literal: true

class Typesensual
  class Callbacks
    def initialize(index)
      @index = index
    end

    def after_create_commit(record)
      @index.index_one(record.id)
    end

    def after_update_commit(record)
      @index.index_one(record.id)
    end

    def after_destroy_commit(record)
      @index.remove_one(record.id)
    end
  end
end
