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
    attr_accessor :config

    def client
      config&.client
    end

    def configure(&block)
      self.config = Typesensual::Config.new(&block)
    end

    # Get the collections that match the alias name
    #
    # @return [Array<Collection>] the collections that match the alias name
    def collections
      Typesensual.client.collections.retrieve.map do |collection|
        Collection.new(collection)
      end
    end

    def aliases
      Typesensual.client.aliases.retrieve['aliases'].to_h do |item|
        [item['name'], item['collection_name']]
      end
    end
  end
end
