# frozen_string_literal: true

require 'json'

require 'active_support/concern'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/class/subclasses'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/hash/keys'

require 'typesense'

require 'typesensual/version'
require 'typesensual/config'
require 'typesensual/index'
require 'typesensual/collection'
require 'typesensual/search'
require 'typesensual/railtie' if defined?(Rails)

class Typesensual
  class << self
    def client
      config&.client
    end

    def configure(&block)
      @config = Typesensual::Config.new(&block)
    end

    def config
      @config ||= Typesensual::Config.new
    end

    # Get the collections that match the alias name
    #
    # @return [Array<Collection>] the collections that match the alias name
    def collections
      Typesensual.client.collections.retrieve.map do |collection|
        Collection.new(collection)
      end
    end
  end
end
