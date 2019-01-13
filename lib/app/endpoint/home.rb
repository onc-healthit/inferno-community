# frozen_string_literal: true

module Inferno
  class App
    class Endpoint
      # Home provides a Sinatra endpoint for accessing Inferno.
      # Home serves the main web application.
      class Home < Endpoint
        # Set the url prefix these routes will map to
        set :prefix, '/inferno'

        # Return the index page of the application
        get '/?' do
          erb :index, {}, modules: settings.modules
        end

        # Returns the static files associated with web app
        get '/static/*' do
          call! env.merge('PATH_INFO' => '/' + params['splat'].first)
        end


        # Resume oauth2 flow
        # This must be early so it doesn't get picked up by the other routes
        get '/oauth2/:key/:endpoint/?' do
          
          instance = nil
          if params[:endpoint] == 'redirect' && !params[:state].nil?
            instance = Inferno::Models::TestingInstance.first(state: params[:state])
            halt 500, "Error: No actively running launch sequences found with a state of #{params[:state]}." if instance.nil?
          end
          if params[:endpoint] == 'launch'
            recent_results = Inferno::Models::SequenceResult.all(:created_at.gte => 5.minutes.ago, :result => 'wait', :order => [:created_at.desc])
            matching_results = recent_results.select{|sr| sr.testing_instance.url.downcase.chomp('/') == params[:iss].downcase.chomp('/')}
            instance = matching_results.first.try(:testing_instance)
            halt 500, "Error: No actively running launch sequences found for iss #{params[:iss]}.  Please ensure that the EHR launch test is actively running before attempting to launch Inferno from the EHR." if instance.nil?
          end

          halt 500, 'Error: No Could not find a running test that match this set of critera' unless !instance.nil? &&
                          instance.client_endpoint_key == params[:key] &&
                          %w[launch redirect].include?(params[:endpoint])
          

          sequence_result = instance.waiting_on_sequence
          test_set = instance.module.test_sets[sequence_result.test_set_id.to_sym]

          if sequence_result.nil? || sequence_result.result != 'wait'
            redirect "#{BASE_PATH}/#{instance.id}/#{test_set.id}/?error=no_#{params[:endpoint]}"
          else
            klass = instance.module.sequences.find { |x| x.sequence_name == sequence_result.name }

            client = FHIR::Client.new(instance.url)
            client.use_dstu2 if instance.fhir_version == 'dstu2'
            client.default_json
            sequence = klass.new(instance, client, settings.disable_tls_tests, sequence_result)

            timer_count = 0
            stayalive_timer_seconds = 20

            stream do |out|
              EventMachine::PeriodicTimer.new(stayalive_timer_seconds) do
                timer_count += 1
                out << js_stayalive(timer_count * stayalive_timer_seconds)
              end

              out << erb(instance.module.view_by_test_set(test_set.id), {}, instance: instance,
                                       sequence_results: instance.latest_results,
                                       test_set: test_set,
                                       tests_running: true)

              out << js_hide_wait_modal
              out << js_show_test_modal
              count = sequence_result.test_results.length
              sequence_result = sequence.resume(request, headers, request.params) do |result|
                count += 1
                out << js_update_result(sequence, test_set, result, count, sequence.test_count)
                instance.save!
              end
              instance.sequence_results.push(sequence_result)
              instance.save!
              out << if sequence_result.redirect_to_url
                       js_redirect_modal(sequence_result.redirect_to_url, sequence_result, instance)
                     else
                       js_redirect("#{BASE_PATH}/#{instance.id}/#{test_set.id}/##{sequence_result.name}")
                     end
            end
          end
        end

        # Returns a specific testing instance test page
        get '/:id/?' do
          instance = Inferno::Models::TestingInstance.get(params[:id])
          halt 404 if instance.nil?

          redirect "#{base_path}/#{instance.id}/#{instance.module.default_test_set}/#{'?error=' + params[:error] unless params[:error].nil?}"
        end

        # Returns a specific testing instance test page
        get '/:id/:test_set/?' do
          instance = Inferno::Models::TestingInstance.get(params[:id])
          halt 404 if instance.nil?
          test_set = instance.module.test_sets[params[:test_set].to_sym]
          halt 404 if test_set.nil?
          sequence_results = instance.latest_results

          erb instance.module.view_by_test_set(params[:test_set]), {}, instance: instance,
                            test_set: test_set,
                            sequence_results: sequence_results,
                            error_code: params[:error]
        end

        # Creates a new testing instance at the provided FHIR Server URL
        post '/?' do
          url = params['fhir_server']
          url = url.chomp('/') if url.end_with?('/')
          inferno_module = params['module']
          @instance = Inferno::Models::TestingInstance.new(url: url,
                                                           name: params['name'],
                                                           base_url: request.base_url,
                                                           selected_module: inferno_module)

                                                        
          
           @instance.client_endpoint_key = params['client_endpoint_key'] unless params['client_endpoint_key'].nil?
          
          @instance.save!
          redirect "#{base_path}/#{@instance.id}/#{'?autoRun=CapabilityStatementSequence' if
              settings.autorun_capability}"
        end

        # Returns test details for a specific test including any applicable requests and responses.
        #   This route is typically used for retrieving test metadata before the test has been run
        get '/test_details/:module/:sequence_name/:test_index?' do
          sequence = Inferno::Module.get(params[:module]).sequences.find do |x|
            x.sequence_name == params[:sequence_name]
          end
          halt 404 unless sequence
          @test_metadata = sequence.tests[params[:test_index].to_i]
          halt 404 unless @test_metadata
          erb :test_details, layout: false
        end

        # Returns test details for a specific test including any applicable requests and responses.
        #   This route is typically used for retrieving test metadata and results after the test has been run.
        get '/:id/test_result/:test_result_id/?' do
          @test_result = Inferno::Models::TestResult.get(params[:test_result_id])
          halt 404 if @test_result.sequence_result.testing_instance.id != params[:id]
          erb :test_result_details, layout: false
        end

        # Cancels the currently running test
        get '/:id/:test_set/sequence_result/:sequence_result_id/cancel' do
          @sequence_result = Inferno::Models::SequenceResult.get(params[:sequence_result_id])
          halt 404 if @sequence_result.testing_instance.id != params[:id]
          test_set = @sequence_result.testing_instance.module.test_sets[params[:test_set].to_sym]
          halt 404 if test_set.nil?

          @sequence_result.result = 'cancel'
          cancel_message = 'Test cancelled by user.'

          unless @sequence_result.test_results.empty?
            last_result = @sequence_result.test_results.last
            last_result.result = 'cancel'
            last_result.message = cancel_message
          end

          sequence = @sequence_result.testing_instance.module.sequences.find do |x|
            x.sequence_name == @sequence_result.name
          end

          current_test_count = @sequence_result.test_results.length

          sequence.tests.each_with_index do |test, index|
            next if index < current_test_count
            @sequence_result.test_results << Inferno::Models::TestResult.new(test_id: test[:test_id],
                                                                             name: test[:name],
                                                                             result: 'cancel',
                                                                             url: test[:url],
                                                                             description: test[:description],
                                                                             test_index: test[:test_index],
                                                                             message: cancel_message)
          end

          @sequence_result.save!

          redirect "#{base_path}/#{params[:id]}/#{params[:test_set]}/##{@sequence_result.name}"
        end

        get '/:id/:test_set/sequence_result?' do
           redirect "#{base_path}/#{params[:id]}/#{params[:test_set]}/"
        end

        # Run a sequence and get the results
        post '/:id/:test_set/sequence_result?' do
          instance = Inferno::Models::TestingInstance.get(params[:id])
          halt 404 if instance.nil?
          test_set = instance.module.test_sets[params[:test_set].to_sym]
          halt 404 if test_set.nil?

          # Save params
          params[:required_fields].split(',').each do |field|
            instance.send("#{field}=", params[field]) if instance.respond_to? field
          end

          instance.save!

          client = FHIR::Client.new(instance.url)
          client.use_dstu2 if instance.fhir_version == 'dstu2'
          client.default_json
          submitted_sequences = params[:sequence].split(',')

          timer_count = 0
          stayalive_timer_seconds = 20

          finished = false
          stream :keep_open do |out|
            EventMachine::PeriodicTimer.new(stayalive_timer_seconds) do
              timer_count += 1
              out << js_stayalive(timer_count * stayalive_timer_seconds)
            end

            out << erb(instance.module.view_by_test_set(params[:test_set]), {}, instance: instance,
                                    test_set: test_set,
                                    sequence_results: instance.latest_results,
                                    tests_running: true)

            next_sequence = submitted_sequences.shift
            until next_sequence.nil?
              klass = instance.module.sequences.find do |x|
                x.sequence_name == next_sequence
              end

              next_sequence = submitted_sequences.shift
              next if klass.nil?

              out << js_show_test_modal

              sequence = klass.new(instance, client, settings.disable_tls_tests)
              count = 0
              sequence_result = sequence.start do |result|
                count += 1
                out << js_update_result(sequence, test_set, result, count, sequence.test_count)
              end

              sequence_result.test_set_id = test_set.id

              sequence_result.next_sequences = submitted_sequences.join(',')

              sequence_result.save!
              if sequence_result.redirect_to_url
                out << js_redirect_modal(sequence_result.redirect_to_url, sequence_result, instance)
                # out << js_redirect(sequence_result.redirect_to_url)
              elsif !submitted_sequences.empty?
                out << js_next_sequence(sequence_result.next_sequences)
              else
                finished = true
              end
            end
            out << js_redirect("#{base_path}/#{params[:id]}/#{params[:test_set]}/##{params[:sequence]}") if finished
          end
        end


        
      end
    end
  end
end
