# frozen_string_literal: true

module Inferno
  class App
    class Endpoint
      # Home provides a Sinatra endpoint for accessing Inferno.
      # Home serves the main web application.
      class Home < Endpoint
        # Set the url prefix these routes will map to
        set :prefix, "/#{base_path}"

        # Return the index page of the application
        get '/?' do
          erb :index, {}, modules: settings.modules.map{|m| Inferno::Module.get(m)}.select{|m| !m.nil?}
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
            matching_results = recent_results.select{|sr| sr.testing_instance.url.downcase.split('://').last.chomp('/') == params[:iss].downcase.split('://').last.chomp('/')}
            
            instance = matching_results.first.try(:testing_instance)
            halt 500, "Error: No actively running launch sequences found for iss #{params[:iss]}.  Please ensure that the EHR launch test is actively running before attempting to launch Inferno from the EHR." if instance.nil?
          end
          halt 500, 'Error: Could not find a running test that match this set of critera' unless !instance.nil? &&
                          instance.client_endpoint_key == params[:key] &&
                          %w[launch redirect].include?(params[:endpoint])


          sequence_result = instance.waiting_on_sequence
          test_set = instance.module.test_sets[sequence_result.test_set_id.to_sym]

          if sequence_result.nil? || sequence_result.result != 'wait'
            redirect "#{BASE_PATH}/#{instance.id}/#{test_set.id}/?error=no_#{params[:endpoint]}"
          else
            test_case = test_set.test_case_by_id(sequence_result.test_case_id)
            test_group = test_case.test_group

            client = FHIR::Client.new(instance.url)
            client.use_dstu2 if instance.fhir_version == 'dstu2'
            client.default_json
            sequence = test_case.sequence.new(instance, client, settings.disable_tls_tests, sequence_result)

            timer_count = 0
            stayalive_timer_seconds = 20

            finished = false

            stream :keep_open do |out|
              EventMachine::PeriodicTimer.new(stayalive_timer_seconds) do
                timer_count += 1
                out << js_stayalive(timer_count * stayalive_timer_seconds)
              end

              # finish the inprocess stream

              out << erb(instance.module.view_by_test_set(test_set.id), {}, instance: instance,
                                      test_set: test_set,
                                      sequence_results: instance.latest_results_by_case,
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

              submitted_test_cases = sequence_result.next_test_cases.split(',')

              next_test_case = submitted_test_cases.shift
              finished = next_test_case.nil?
              if sequence_result.redirect_to_url
                out << js_redirect_modal(sequence_result.redirect_to_url, sequence_result, instance)
                next_test_case = nil
                finished = false
              elsif !submitted_test_cases.empty?
                out << js_next_sequence(sequence_result.next_test_cases)
              else
                finished = true
              end

              # continue processesing any afterwards


              until next_test_case.nil?
                test_case = test_set.test_case_by_id(next_test_case)

                next_test_case = submitted_test_cases.shift
                if test_case.nil?
                  finished = next_test_case.nil?
                  next
                end

                out << js_show_test_modal

                sequence = test_case.sequence.new(instance, client, settings.disable_tls_tests)
                count = 0
                sequence_result = sequence.start do |result|
                  count += 1
                  out << js_update_result(sequence, test_set, result, count, sequence.test_count)
                end

                sequence_result.test_set_id = test_set.id
                sequence_result.test_case_id = test_case.id

                sequence_result.next_test_cases = ([next_test_case] + submitted_test_cases).join(',')

                sequence_result.save!
                if sequence_result.redirect_to_url
                  out << js_redirect_modal(sequence_result.redirect_to_url, sequence_result, instance)
                  finished = false
                elsif !submitted_test_cases.empty?
                  out << js_next_sequence(sequence_result.next_test_cases)
                else
                  finished = true
                end
              end

              query_target = "#{params[:test_case]}"
              unless test_group.nil?
                query_target = "#{test_group.id}/#{test_case.id}"
              end

              out << js_redirect("#{base_path}/#{instance.id}/#{test_set.id}/##{query_target}") if finished

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
          sequence_results = instance.latest_results_by_case

          erb instance.module.view_by_test_set(params[:test_set]), {}, instance: instance,
                            test_set: test_set,
                            sequence_results: sequence_results,
                            error_code: params[:error]
        end

        get '/:id/:test_set/report?' do
          instance = Inferno::Models::TestingInstance.get(params[:id])
          halt 404 if instance.nil?
          test_set = instance.module.test_sets[params[:test_set].to_sym]
          halt 404 if test_set.nil?
          sequence_results = instance.latest_results_by_case
          latest_sequence_time = nil

          request_response_count = 0
          instance.sequence_results.each do |sequence_result|
            if latest_sequence_time == nil || latest_sequence_time < sequence_result.created_at then
              latest_sequence_time = sequence_result.created_at
            end
            sequence_result.test_results.each do |test_result|
              request_response_count = request_response_count + test_result.request_responses.count
            end
          end

          if latest_sequence_time == nil then
            latest_sequence_time = "No tests ran"
          else
            latest_sequence_time = latest_sequence_time.strftime("%m/%d/%Y %H:%M")
          end
          report_summary = {
            resource_references: instance.resource_references.count,
            supported_resources: instance.supported_resources.count,
            request_response: request_response_count,
            latest_sequence_time: latest_sequence_time,
            final_result: instance.final_result
          }
          
          erb :report, {:layout => false}, instance: instance,  test_set:test_set, show_button: false, sequence_results:sequence_results, report_summary:report_summary
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

          @instance.initiate_login_uri = "#{request.base_url}#{base_path}/oauth2/#{@instance.client_endpoint_key}/launch"
          @instance.redirect_uris = "#{request.base_url}#{base_path}/oauth2/#{@instance.client_endpoint_key}/redirect"

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
          sequence_result = Inferno::Models::SequenceResult.get(params[:sequence_result_id])
          halt 404 if sequence_result.testing_instance.id != params[:id]
          test_set = sequence_result.testing_instance.module.test_sets[params[:test_set].to_sym]
          halt 404 if test_set.nil?

          sequence_result.result = 'cancel'
          cancel_message = 'Test cancelled by user.'

          unless sequence_result.test_results.empty?
            last_result = sequence_result.test_results.last
            last_result.result = 'cancel'
            last_result.message = cancel_message
          end

          sequence = sequence_result.testing_instance.module.sequences.find do |x|
            x.sequence_name == sequence_result.name
          end

          current_test_count = sequence_result.test_results.length

          sequence.tests.each_with_index do |test, index|
            next if index < current_test_count
            sequence_result.test_results << Inferno::Models::TestResult.new(test_id: test[:test_id],
                                                                             name: test[:name],
                                                                             result: 'cancel',
                                                                             url: test[:url],
                                                                             description: test[:description],
                                                                             test_index: test[:test_index],
                                                                             message: cancel_message)
          end

          sequence_result.save!

          test_group = nil
          test_group = test_set.test_case_by_id(sequence_result.test_case_id).test_group

          query_target = sequence_result.test_case_id
          unless test_group.nil?
            query_target = "#{test_group.id}/#{sequence_result.test_case_id}"
          end

          redirect "#{base_path}/#{params[:id]}/#{params[:test_set]}/##{query_target}"
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
          submitted_test_cases = params[:test_case].split(',')
          test_group = nil
          test_group = test_set.test_case_by_id(submitted_test_cases.first).test_group

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
                                    sequence_results: instance.latest_results_by_case,
                                    tests_running: true)

            next_test_case = submitted_test_cases.shift
            finished = next_test_case.nil?

            until next_test_case.nil?
              test_case = test_set.test_case_by_id(next_test_case)

              next_test_case = submitted_test_cases.shift
              if test_case.nil?
                finished = next_test_case.nil?
                next
              end

              out << js_show_test_modal

              sequence = test_case.sequence.new(instance, client, settings.disable_tls_tests)
              count = 0
              sequence_result = sequence.start(test_set.id, test_case.id) do |result|
                count += 1
                out << js_update_result(sequence, test_set, result, count, sequence.test_count)
              end

              sequence_result.next_test_cases = ([next_test_case] + submitted_test_cases).join(',')

              sequence_result.save!
              if sequence_result.redirect_to_url
                out << js_redirect_modal(sequence_result.redirect_to_url, sequence_result, instance)
                next_test_case = nil
                finished = false
              elsif sequence_result.wait_at_endpoint
                next_test_case = nil
                finished = true
              elsif !submitted_test_cases.empty?
                out << js_next_sequence(sequence_result.next_test_cases)
              else
                finished = true
              end
            end

            query_target = params[:test_case]
            unless test_group.nil?
              query_target = "#{test_group.id}/#{test_case.id}"
            end

            out << js_redirect("#{base_path}/#{params[:id]}/#{params[:test_set]}/##{query_target}") if finished
          end
        end



      end
    end
  end
end
