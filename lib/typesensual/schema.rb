# frozen_string_literal: true

require 'typesensual/field'

class Typesensual
  class Schema
    # Duplicate fields from the original
    def initialize_copy(original)
      %w[
        @fields
        @token_separators
        @symbols_to_index
        @default_sorting_field
        @enable_nested_fields
      ].each do |var|
        instance_variable_set(var, original.instance_variable_get(var).dup)
      end
    end

    def initialize(&block)
      instance_eval(&block) unless block.nil?
    end

    def field(name, type: 'auto', locale: nil, facet: nil, index: nil, optional: nil)
      @fields ||= []
      @fields << Field.new(
        name: name,
        type: type,
        locale: locale,
        facet: facet,
        index: index,
        optional: optional
      )
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
        'fields' => @fields&.map(&:to_h),
        'token_separators' => @token_separators,
        'symbols_to_index' => @symbols_to_index,
        'default_sorting_field' => @default_sorting_field,
        'enable_nested_fields' => @enable_nested_fields
      }.compact!
    end
  end
end
