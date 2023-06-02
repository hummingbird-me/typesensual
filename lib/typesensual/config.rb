# frozen_string_literal: true

class Typesensual
  class Config
    attr_accessor :nodes, :api_key
    attr_writer :env, :client

    def initialize(&block)
      yield self if block
    end

    def env
      @env ||= (defined?(Rails) ? Rails.env : nil)
    end

    def client
      @client ||= Typesense::Client.new(connection_options)
    end

    private

    def connection_options
      { nodes: nodes, api_key: api_key }
    end
  end
end
