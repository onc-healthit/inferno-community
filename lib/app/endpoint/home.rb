# frozen_string_literal: true

require_relative 'oauth2_endpoints'
require_relative 'test_set_endpoints'

module Inferno
  class App
    class Endpoint
      # Home provides a Sinatra endpoint for accessing Inferno.
      # Home serves the main web application.
      class Home < Endpoint
        helpers Sinatra::Cookies

        # Set the url prefix these routes will map to
        set :prefix, "/#{base_path}"

        include OAuth2Endpoints
        include TestSetEndpoints

        # Return the index page of the application
        get '/?' do
          render_index
        end

        # Creates a new testing instance at the provided FHIR Server URL
        post '/?' do
          url = params['fhir_server']
          url = url.chomp('/') if url.end_with?('/')
          inferno_module = Inferno::Module.get(params[:module])

          if inferno_module.nil?
            Inferno.logger.error "Unknown module: #{params[:module]}"
            halt 404, "Unknown module: #{params[:module]}"
          end

          @instance = Inferno::Models::TestingInstance.new(url: url,
                                                           name: params['name'],
                                                           base_url: request.base_url,
                                                           selected_module: inferno_module.name)

          @instance.client_endpoint_key = params['client_endpoint_key'] unless params['client_endpoint_key'].nil?

          unless params['preset'].blank?
            preset = JSON.parse(params['preset']) unless params['preset'].nil?
            @instance.client_id = preset['client_id'] unless preset['client_id'].nil?
            @instance.scopes = preset['scopes'] unless preset['scopes'].nil?
            unless preset['client_secret'].nil?
              @instance.confidential_client = true
              @instance.client_secret = preset['client_secret']
            end
          end

          @instance.initiate_login_uri = "#{request.base_url}#{base_path}/oauth2/#{@instance.client_endpoint_key}/launch"
          @instance.redirect_uris = "#{request.base_url}#{base_path}/oauth2/#{@instance.client_endpoint_key}/redirect"

          cookies[:instance_id_test_set] = "#{@instance.id}/test_sets/#{inferno_module.default_test_set}"

          @instance.save!
          redirect "#{base_path}/#{@instance.id}/#{'?autoRun=CapabilityStatementSequence' if
              settings.autorun_capability}"
        end

        # Returns the static files associated with web app
        get '/static/*' do
          call! env.merge('PATH_INFO' => '/' + params['splat'].first)
        end

        # Returns a specific testing instance test page
        get '/:id/?' do
          instance = Inferno::Models::TestingInstance.get(params[:id])
          halt 404 if instance.nil?

          redirect "#{base_path}/#{instance.id}/test_sets/#{instance.module.default_test_set}/#{'?error=' + params[:error] unless params[:error].nil?}"
        end

        # Returns test details for a specific test including any applicable requests and responses.
        #   This route is typically used for retrieving test metadata before the test has been run
        get '/test_details/:module/:sequence_name/:test_index?' do
          sequence = Inferno::Module.get(params[:module]).sequences.find do |x|
            x.sequence_name == params[:sequence_name]
          end
          halt 404 unless sequence
          @test = sequence.tests[params[:test_index].to_i]
          halt 404 unless @test.present?
          erb :test_details, layout: false
        end

        # Returns test details for a specific test including any applicable requests and responses.
        #   This route is typically used for retrieving test metadata and results after the test has been run.
        get '/:id/test_result/:test_result_id/?' do
          @test_result = Inferno::Models::TestResult.get(params[:test_result_id])
          halt 404 if @test_result.sequence_result.testing_instance.id != params[:id]
          erb :test_result_details, layout: false
        end

        # Returns details for a specific request response
        #   This route is typically used for retrieving test metadata and results after the test has been run.
        get '/:id/test_request/:test_request_id/?' do
          request_response = Inferno::Models::RequestResponse.get(params[:test_request_id])
          halt 404 if request_response.instance_id != params[:id]
          erb :request_details, { layout: false }, rr: request_response
        end
      end
    end
  end
end
