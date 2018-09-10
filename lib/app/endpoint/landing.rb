module Inferno
  class App
    class Endpoint
      class Landing < Endpoint
        #get '/' do
        #  status, headers, body = call! env.merge("PATH_INFO" => BASE_PATH)
        #end

        get '/' do
          # Custom landing page intended to be overwritten for branded deployments
          erb :landing
        end
      end
    end
  end
end