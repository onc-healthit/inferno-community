# frozen_string_literal: true

module Inferno
  class App
    class Endpoint
      # Home provides a Sinatra endpoint for accessing Inferno.
      # Home serves the index page and landing page
      class Landing < Endpoint
        set :prefix, '/'

        # Return the index page of the application
        get '/' do
          logger.info 'loading index page.'
          render_index
        end

        get '/landing/?' do
          # Custom landing page intended to be overwritten for branded deployments
          erb :landing
        end

        # Serve our public key in a JWKS
        get '/jwks' do
          if File.exist?('keyfile')
            key_str = File.read('keyfile')
            key = OpenSSL::PKey::RSA.new(key_str)
          else
            key = OpenSSL::PKey::RSA.generate(2048)
            File.write('keyfile', key.export)
          end

          jwk = JSON::JWK.new(key.public_key)
          jwks = JSON::JWK::Set.new(jwk)
          jwks.to_json
        end
      end
    end
  end
end
