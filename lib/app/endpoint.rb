# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/custom_logger'
require 'sinatra/cookies'
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
      Inferno::EXTRAS = settings.include_extras

      if settings.logging_enabled
        $stdout.sync = true # output in Docker is heavily delayed without this
        Inferno.logger =
          if ENV['RACK_ENV'] == 'test'
            FileUtils.mkdir_p 'tmp'
            ::Logger.new(File.join('tmp', 'test.log'), level: settings.log_level.to_sym, progname: 'Inferno')
          elsif settings.log_to_file
            ::Logger.new('logs.log', level: settings.log_level.to_sym, progname: 'Inferno')
          else
            l = ::Logger.new(STDOUT, level: settings.log_level.to_sym, progname: 'Inferno')
            l.formatter = proc do |severity, _datetime, progname, msg|
              "#{severity} | #{progname} | #{msg}\n"
            end
            l
          end

        # FIXME: Really don't want a direct dependency to DataMapper here
        DataMapper.logger = Inferno.logger if Inferno::ENVIRONMENT == :development

        FHIR.logger = FHIR::STU3.logger = FHIR::DSTU2.logger = Inferno.logger

        Inferno.logger.info "Environment: #{Inferno::ENVIRONMENT}"

        helpers Sinatra::CustomLogger

        configure :development, :production do
          set :logger, Inferno.logger
          use Rack::CommonLogger, Inferno.logger
        end
      end

      helpers Helpers::Configuration
      helpers Helpers::BrowserLogic

      set :public_folder, (proc { File.join(root, '../../public') })
      set :static, true
      set :views, File.expand_path('views', __dir__)
      set(:prefix) { '/' << name[/[^:]+$/].underscore }

      def render_index
        unless defined?(settings.presets).nil? || settings.presets.nil?
          base_url = request.base_url
          base_path = Inferno::BASE_PATH&.chomp('/')

          presets = settings.presets.select do |_, v|
            inferno_uri = v['inferno_uri']&.chomp('/')
            inferno_uri.nil? || inferno_uri == base_url || inferno_uri == base_url + base_path
          end
        end
        modules = settings.modules.map { |m| Inferno::Module.get(m) }.compact
        erb :index, {}, modules: modules, presets: presets
      end
    end
  end
end

require_relative 'endpoint/landing'
require_relative 'endpoint/home'
