module Inferno
  class App
    class Endpoint
      class Landing < Endpoint

        set :prefix, '/'

        get '/' do
          logger.info 'loading index page.'
          erb :index
        end

        get '/landing/?' do
          # Custom landing page intended to be overwritten for branded deployments
          erb :landing
        end
      end
    end
  end
end