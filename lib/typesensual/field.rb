# frozen_string_literal: true

class Typesensual
  class Field
    def initialize(hash = nil)
      @field = hash&.stringify_keys
    end

    def facet?
      @field['facet']
    end

    def index?
      @field['index']
    end

    def infix?
      @field['infix']
    end

    def locale
      @field['locale'].presence
    end

    def name
      if @field['name'].is_a?(Regexp)
        @field['name'].source
      else
        @field['name'].to_s
      end
    end

    def optional?
      @field['optional']
    end

    def sort?
      @field['sort']
    end

    def type
      @field['type']
    end

    def to_h
      @field.to_h.merge!(
        'name' => name,
        'locale' => locale
      ).compact!
    end
  end
end
