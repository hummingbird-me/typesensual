# frozen_string_literal: true

class Typesensual
  class Config
    attr_writer :env, :client, :nodes, :api_key

    def initialize(&block)
      yield self if block
    end

    def env
      @env ||= ENV.fetch('TYPESENSUAL_ENV', (defined?(Rails) ? Rails.env : nil))
    end

    def client
      @client ||= Typesense::Client.new(connection_options)
    end

    def nodes
      @nodes ||= ENV['TYPESENSUAL_NODES']&.split(',')&.map do |node|
        node_uri = URI.parse(node)
        { port: node_uri.port, host: node_uri.host, protocol: node_uri.scheme }
      end
    end

    def api_key
      @api_key ||= ENV.fetch('TYPESENSUAL_API_KEY', nil)
    end

    private

    def connection_options
      { nodes: nodes, api_key: api_key }
    end
  end
end
