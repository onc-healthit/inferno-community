# frozen_string_literal: true

module Inferno
  class App
    class Endpoint
      # Home provides a Sinatra endpoint for accessing Inferno.
      # Home serves the main web application.
      class Home < Endpoint
        helpers Sinatra::Cookies
        # Set the url prefix these routes will map to
        set :prefix, "/#{base_path}"

        # Return the index page of the application
        get '/?' do
          render_index
        end

        # Returns the static files associated with web app
        get '/static/*' do
          call! env.merge('PATH_INFO' => '/' + params['splat'].first)
        end

        # Resume oauth2 flow
        # This must be early so it doesn't get picked up by the other routes
        get '/oauth2/:key/:endpoint/?' do
          instance = nil
          error_message = nil

          if params[:endpoint] == 'redirect'
            instance = Inferno::Models::TestingInstance.first(state: params[:state])
            if instance.nil?
              instance = Inferno::Models::TestingInstance.get(cookies[:instance_id_test_set]&.split('/')&.first)
              if instance.nil?
                error_message = %(
                               <p>
                                  Inferno has detected an issue with the SMART launch.
                                  No actively running launch sequences found with a state of #{params[:state]}.
                                  The authorization server is not returning the correct state variable and
                                  therefore Inferno cannot identify which server is currently under test.
                                  Please click your browser's "Back" button to return to Inferno,
                                  and click "Refresh" to ensure that the most recent test results are visible.
                                </p>
                                )

                error_message += "<p>Error returned by server: <strong>#{params[:error]}</strong>.</p>" if params[:error].present?

                error_message += "<p>Error description returned by server: <strong>#{params[:error_description]}</strong>.</p>" unless params[:error_description].nil?

                halt 500, error_message
              elsif instance&.waiting_on_sequence&.wait?
                error_message = "State provided in redirect (#{params[:state]}) does not match expected state (#{instance.state})."
              else
                redirect "#{base_path}/#{cookies[:instance_id_test_set]}/?error=no_state&state=#{params[:state]}"
              end
            end
          end

          if params[:endpoint] == 'launch'
            recent_results = Inferno::Models::SequenceResult.all(
              :created_at.gte => 5.minutes.ago,
              :result => 'wait',
              :order => [:created_at.desc]
            )
            iss_url = params[:iss]&.downcase&.split('://')&.last&.chomp('/')

            matching_results = recent_results.select do |sr|
              testing_instance_url = sr.testing_instance.url.downcase.split('://').last.chomp('/')
              testing_instance_url == iss_url
            end

            instance = matching_results&.first&.testing_instance
            if instance.nil?
              instance = Inferno::Models::TestingInstance.get(cookies[:instance_id_test_set]&.split('/')&.first)
              if instance.nil?
                message = "Error: No actively running launch sequences found for iss #{params[:iss]}. " \
                          'Please ensure that the EHR launch test is actively running before attempting to launch Inferno from the EHR.'
                halt 500, message
              elsif instance&.waiting_on_sequence&.wait?
                error_message = 'No iss for redirect'
              else
                redirect "#{base_path}/#{cookies[:instance_id_test_set]}/?error=no_ehr_launch&iss=#{params[:iss]}"
              end
            end
          end
          halt 500, 'Error: Could not find a running test that match this set of critera' unless !instance.nil? &&
                                                                                                 instance.client_endpoint_key == params[:key] &&
                                                                                                 %w[launch redirect].include?(params[:endpoint])

          sequence_result = instance.waiting_on_sequence
          if sequence_result&.wait?
            test_set = instance.module.test_sets[sequence_result.test_set_id.to_sym]
            failed_test_cases = []
            all_test_cases = []
            test_case = test_set.test_case_by_id(sequence_result.test_case_id)
            test_group = test_case.test_group

            client = FHIR::Client.new(instance.url)
            case instance.fhir_version
            when 'stu3'
              client.use_stu3
            when 'dstu2'
              client.use_dstu2
            else
              client.use_r4
            end
            client.default_json
            sequence = test_case.sequence.new(instance, client, settings.disable_tls_tests, sequence_result)
            first_test_count = sequence.test_count

            timer_count = 0
            stayalive_timer_seconds = 20

            finished = false

            stream :keep_open do |out|
              EventMachine::PeriodicTimer.new(stayalive_timer_seconds) do
                timer_count += 1
                out << js_stayalive(timer_count * stayalive_timer_seconds)
              end

              # finish the inprocess stream

              out << erb(instance.module.view_by_test_set(test_set.id),
                         {},
                         instance: instance,
                         test_set: test_set,
                         sequence_results: instance.latest_results_by_case,
                         tests_running: true)

              out << js_hide_wait_modal
              out << js_show_test_modal
              count = sequence_result.test_results.length

              submitted_test_cases_count = sequence_result.next_test_cases.split(',')
              total_tests = submitted_test_cases_count.reduce(first_test_count) do |total, set|
                sequence_test_count = test_set.test_case_by_id(set).sequence.test_count
                total + sequence_test_count
              end

              sequence_result = sequence.resume(request, headers, request.params, error_message) do |result|
                count += 1
                out << js_update_result(sequence, test_set, result, count, sequence.test_count, count, total_tests)
                instance.save!
              end
              all_test_cases << test_case.id
              failed_test_cases << test_case.id if sequence_result.fail?
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

              test_count = first_test_count
              until next_test_case.nil?
                test_case = test_set.test_case_by_id(next_test_case)

                next_test_case = submitted_test_cases.shift
                if test_case.nil?
                  finished = next_test_case.nil?
                  next
                end

                out << js_show_test_modal

                instance.reload # ensure that we have all the latest data
                sequence = test_case.sequence.new(instance, client, settings.disable_tls_tests)
                count = 0
                sequence_result = sequence.start do |result|
                  test_count += 1
                  count += 1
                  out << js_update_result(sequence, test_set, result, count, sequence.test_count, test_count, total_tests)
                end
                all_test_cases << test_case.id
                failed_test_cases << test_case.id if sequence_result.fail?

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

              query_target = failed_test_cases.join(',')
              query_target = all_test_cases.join(',') if all_test_cases.length == 1

              query_target = "#{test_group.id}/#{query_target}" unless test_group.nil?

              out << js_redirect("#{base_path}/#{instance.id}/#{test_set.id}/##{query_target}") if finished
            end
          else
            latest_sequence_result = Inferno::Models::SequenceResult.first(testing_instance: instance)
            test_set_id = latest_sequence_result&.test_set_id || instance.module.default_test_set
            redirect "#{BASE_PATH}/#{instance.id}/#{test_set_id}/?error=no_#{params[:endpoint]}"
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

          request_response_count = Inferno::Models::RequestResponse.all(instance_id: instance.id).count
          latest_sequence_time =
            if instance.sequence_results.count.positive?
              Inferno::Models::SequenceResult.first(testing_instance: instance).created_at.strftime('%m/%d/%Y %H:%M')
            else
              'No tests ran'
            end

          report_summary = {
            fhir_version: instance.fhir_version,
            app_version: VERSION,
            resource_references: instance.resource_references.count,
            supported_resources: instance.supported_resources.count,
            request_response: request_response_count,
            latest_sequence_time: latest_sequence_time,
            final_result: instance.final_result,
            inferno_url: "#{request.base_url}#{base_path}/#{instance.id}/#{params[:test_set]}/"
          }

          erb(
            :report,
            { layout: false },
            instance: instance,
            test_set: test_set,
            show_button: false,
            sequence_results: sequence_results,
            report_summary: report_summary
          )
        end

        # Creates a new testing instance at the provided FHIR Server URL
        post '/?' do
          url = params['fhir_server']
          url = url.chomp('/') if url.end_with?('/')
          inferno_module = Inferno::Module.get(params[:module])

          if inferno_module.nil?
            FHIR.logger.error "Unknown module: #{params[:module]}"
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

          cookies[:instance_id_test_set] = "#{@instance.id}/#{inferno_module.default_test_set}"

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

        # Returns details for a specific request response
        #   This route is typically used for retrieving test metadata and results after the test has been run.
        get '/:id/test_request/:test_request_id/?' do
          request_response = Inferno::Models::RequestResponse.get(params[:test_request_id])
          halt 404 if request_response.instance_id != params[:id]
          erb :request_details, { layout: false }, rr: request_response
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

          test_group = test_set.test_case_by_id(sequence_result.test_case_id).test_group

          query_target = sequence_result.test_case_id
          query_target = "#{test_group.id}/#{sequence_result.test_case_id}" unless test_group.nil?

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

          cookies[:instance_id_test_set] = "#{instance.id}/#{params[:test_set]}"

          # Save params
          params[:required_fields].split(',').each do |field|
            instance.send("#{field}=", params[field]) if instance.respond_to? field
          end

          instance.save!

          client = FHIR::Client.new(instance.url)
          case instance.fhir_version
          when 'stu3'
            client.use_stu3
          when 'dstu2'
            client.use_dstu2
          else
            client.use_r4
          end
          client.default_json
          submitted_test_cases = params[:test_case].split(',')

          instance.reload # ensure that we have all the latest data

          total_tests = submitted_test_cases.reduce(0) do |total, set|
            sequence_test_count = test_set.test_case_by_id(set).sequence.test_count
            total + sequence_test_count
          end

          test_group = nil
          test_group = test_set.test_case_by_id(submitted_test_cases.first).test_group
          failed_test_cases = []
          all_test_cases = []

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

            test_count = 0
            until next_test_case.nil?
              test_case = test_set.test_case_by_id(next_test_case)

              next_test_case = submitted_test_cases.shift
              if test_case.nil?
                finished = next_test_case.nil?
                next
              end

              out << js_show_test_modal

              instance.reload # ensure that we have all the latest data
              sequence = test_case.sequence.new(instance, client, settings.disable_tls_tests)
              count = 0
              sequence_result = sequence.start(test_set.id, test_case.id) do |result|
                count += 1
                test_count += 1
                out << js_update_result(sequence, test_set, result, count, sequence.test_count, test_count, total_tests)
              end

              sequence_result.next_test_cases = ([next_test_case] + submitted_test_cases).join(',')

              all_test_cases << test_case.id
              failed_test_cases << test_case.id if sequence_result.fail?

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

            query_target = failed_test_cases.join(',')
            query_target = all_test_cases.join(',') if all_test_cases.length == 1

            query_target = "#{test_group.id}/#{query_target}" unless test_group.nil?

            out << js_redirect("#{base_path}/#{params[:id]}/#{params[:test_set]}/##{query_target}") if finished
          end
        end
      end
    end
  end
end
