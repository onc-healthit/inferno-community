# frozen_string_literal: true

module Inferno
  class App
    module OAuth2Endpoints
      def self.included(klass)
        klass.class_eval do
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
                           tests_running: true,
                           test_group: test_group.id)

                out << js_hide_wait_modal
                out << js_show_test_modal
                count = sequence_result.result_count

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

                out << js_redirect("#{base_path}/#{instance.id}/test_sets/#{test_set.id}/##{query_target}") if finished
              end
            else
              latest_sequence_result = Inferno::Models::SequenceResult.first(testing_instance: instance)
              test_set_id = latest_sequence_result&.test_set_id || instance.module.default_test_set
              redirect "#{BASE_PATH}/#{instance.id}/test_sets/#{test_set_id}/?error=no_#{params[:endpoint]}"
            end
          end
        end
      end
    end
  end
end
