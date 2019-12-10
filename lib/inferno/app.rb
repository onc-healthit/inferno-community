# frozen_string_literal: true

require 'yaml'
require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/namespace'
require 'sinatra/cookies'
require 'fhir_client'
require 'rest-client'
require 'time_difference'
require 'dm-core'
require 'dm-migrations'
require 'jwt'
require 'json/jwt'
require 'kramdown'

require 'rack'
require_relative 'app/utils/logging'
require_relative 'app/sequence_base'
require_relative 'app/endpoint'
require_relative 'app/utils/secure_random_base62'
require_relative 'app/models/module'
require_relative 'app/models'
require_relative 'app/utils/terminology'

module Inferno
  class App
    attr_reader :app
    def initialize
      @app = Rack::Builder.app do
        Endpoint.subclasses.each do |endpoint|
          map(endpoint.prefix) { run(endpoint.new) }
        end
      end
    end

    # Rack protocol
    def call(env)
      app.call(env)
    end
  end
end
