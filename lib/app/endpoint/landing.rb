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
          unless defined?(settings.presets).nil? || settings.presets.nil?
            presets = Hash[settings.presets.map { |k, v| [k, v] if v['domain'].nil? || v['domain'] == request.base_url }]
          end
          erb :index, {}, modules: settings.modules.map { |m| Inferno::Module.get(m) }.compact, presets: presets
        end

        get '/landing/?' do
          # Custom landing page intended to be overwritten for branded deployments
          erb :landing
        end
      end
    end
  end
end
