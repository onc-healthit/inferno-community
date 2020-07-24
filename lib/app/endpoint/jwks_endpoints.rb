# frozen_string_literal: true

module Inferno
  class App
    module JwksEndpoints
      def self.included(klass)
        klass.class_eval do
          get '/.well-known/jwks.json' do
            content_type :json
            return { 'keys': nil }.to_json unless settings.respond_to? :bulk_data_jwks

            { keys: settings.bulk_data_jwks['keys'].select { |key| key['key_ops']&.include?('verify') } }.to_json
          end
        end
      end
    end
  end
end
