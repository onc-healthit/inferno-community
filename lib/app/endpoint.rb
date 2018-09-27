require 'sinatra/base'
require 'sinatra/custom_logger'
require_relative 'helpers/configuration'
require_relative 'helpers/browser_logic'
module Inferno
  class App
    class Endpoint < Sinatra::Base
      register Sinatra::ConfigFile

      config_file '../../config.yml'

      OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE if settings.disable_verify_peer
      Inferno::BASE_PATH = "/#{settings.base_path.gsub(/[^0-9a-z_-]/i, '')}"
      Inferno::DEFAULT_SCOPES = settings.default_scopes
      Inferno::ENVIRONMENT = settings.environment
      Inferno::PURGE_ON_RELOAD = settings.purge_database_on_reload

      if settings.logging_enabled
        Inferno.logger = if settings.log_to_file
                           ::Logger.new('logs.log', level: settings.log_level.to_sym)
                         else
                           ::Logger.new(STDOUT, level: settings.log_level.to_sym)
                         end

        # FIXME: Really don't want a direct dependency to DataMapper here
        DataMapper.logger = Inferno.logger if Inferno::ENVIRONMENT == :development

        helpers Sinatra::CustomLogger

        configure :development, :production do
          set :logger, Inferno.logger
          use Rack::CommonLogger, Inferno.logger
        end
      end

      helpers Helpers::Configuration
      helpers Helpers::BrowserLogic
      
      set :public_folder, Proc.new { File.join(root, '../../public') }
      set :static, true
      set :views, File.expand_path('../views', __FILE__)
      set(:prefix) { '/' << name[/[^:]+$/].underscore }
    end
  end
end

require_relative 'endpoint/landing'
require_relative 'endpoint/home'