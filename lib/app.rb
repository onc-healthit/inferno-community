# frozen_string_literal: true

require 'yaml'
require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/namespace'
require 'sinatra/cookies'
require 'active_record'
require 'fhir_client'
require 'rest-client'
require 'time_difference'
require 'pry'
require 'pry-byebug'
require 'jwt'
require 'kramdown'

require 'rack'
require_relative 'app/ext/sinatra_base'
require_relative 'app/utils/logging'
require_relative 'app/models'
require_relative 'app/endpoint'
require_relative 'app/utils/secure_random_base62'
require_relative 'app/sequence_base'
require_relative 'app/models/module'
require_relative 'version'
require_relative 'app/utils/terminology'
require_relative 'app/utils/startup_tasks'
require_relative 'app/utils/config_manager'

module Inferno
  class App
    attr_reader :app
    def initialize
      StartupTasks.run

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
