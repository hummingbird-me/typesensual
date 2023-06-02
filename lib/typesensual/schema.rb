# frozen_string_literal: true

class Typesensual
  class Schema
    def initialize(&block)
      instance_eval(&block)
    end

    def field(name, type: 'auto', locale: nil, facet: nil, index: nil, optional: nil)
      name = name.source if name.is_a?(Regexp)

      @fields ||= []
      @fields << {
        name: name.to_s,
        type: type,
        locale: locale,
        facet: facet,
        index: index,
        optional: optional
      }.compact!
    end

    def token_separators(*separators)
      @token_separators = separators
    end

    def symbols_to_index(*symbols)
      @symbols_to_index = symbols
    end

    def default_sorting_field(field_name)
      @default_sorting_field = field_name.to_s
    end

    def enable_nested_fields(value = true) # rubocop:disable Style/OptionalBooleanParameter
      @enable_nested_fields = value
    end

    def to_h
      {
        fields: @fields,
        token_separators: @token_separators,
        symbols_to_index: @symbols_to_index,
        default_sorting_field: @default_sorting_field,
        enable_nested_fields: @enable_nested_fields
      }.compact!
    end
  end
end
