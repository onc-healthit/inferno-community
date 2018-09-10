require 'yaml'
require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/namespace'
require 'fhir_client'
require 'rest-client'
require 'time_difference'
require 'pry'
require 'dm-core'
require 'dm-migrations'
require 'jwt'
require 'json/jwt'

require 'rack'
require_relative 'app/endpoint'
require_relative 'app/models'
require_relative 'app/utils/secure_random_base62'
require_relative 'app/sequence_base'

module Inferno
  BASE_PATH = '/inferno'.freeze
  VERSION = '0.9.3'.freeze
  DEFAULT_SCOPES = 'launch launch/patient offline_access openid profile user/*.* patient/*.*'
  class App
    attr_reader :app

    def initialize

      @app = Rack::Builder.app do
        Endpoint.subclasses.each do |e|
          map(e.prefix) { run(e.new) }
        end
      end
    end

    # Rack protocol
    def call(env)
      app.call(env)
    end
  end
end
