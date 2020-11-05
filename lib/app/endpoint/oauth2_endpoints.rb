# frozen_string_literal: true

require_relative '../utils/oauth2_error_messages'

module Inferno
  class App
    module OAuth2Endpoints
      def self.included(klass)
        klass.class_eval do
          include OAuth2ErrorMessages

          def running_test_found?
            @instance.present? && @instance.client_endpoint_key == params[:key]
          end

          def instance_id_from_cookie
            cookies[:instance_id_test_set]&.split('/')&.first
          end

          get '/oauth2/:key/redirect/?' do
            @instance = Inferno::TestingInstance.find_by(state: params[:state])
            return resume_execution if @instance.present?

            @instance = Inferno::TestingInstance.find_by(id: instance_id_from_cookie)
            halt 500, no_instance_for_state_error_message if @instance.nil?

            if @instance&.waiting_on_sequence&.wait?
              @error_message = bad_state_error_message
              resume_execution
            else
              redirect "#{base_path}/#{cookies[:instance_id_test_set]}/?error=no_state&state=#{params[:state]}"
            end
          end

          get '/oauth2/:key/launch/?' do
            @instance = Inferno::SequenceResult.recent_results_for_iss(params[:iss])&.testing_instance
            return resume_execution if @instance.present?

            @instance = Inferno::TestingInstance.find_by(id: instance_id_from_cookie)
            halt 500, no_instance_for_iss_error_message if @instance.nil?

            if @instance.waiting_on_sequence&.wait?
              @error_message = unknown_iss_error_message
              resume_execution
            else
              redirect "#{base_path}/#{cookies[:instance_id_test_set]}/?error=no_ehr_launch&iss=#{params[:iss]}"
            end
          end

          def resume_execution
            halt 500, no_running_test_error_message unless running_test_found?

            sequence_result = @instance.waiting_on_sequence
            if sequence_result&.wait?
              test_set = @instance.module.test_sets[sequence_result.test_set_id.to_sym]
              failed_test_cases = []
              all_test_cases = []
              test_case = test_set.test_case_by_id(sequence_result.test_case_id)
              test_group = test_case.test_group

              client = FHIR::Client.for_testing_instance(@instance)
              sequence = test_case.sequence.new(@instance, client, settings.disable_tls_tests, sequence_result)
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

                out << erb(@instance.module.view_by_test_set(test_set.id),
                           {},
                           instance: @instance,
                           test_set: test_set,
                           sequence_results: @instance.latest_results_by_case,
                           tests_running: true,
                           test_group: test_group.id)

                out << js_hide_wait_modal
                out << js_show_test_modal
                count = sequence_result.result_count

                submitted_test_cases_count = sequence_result.next_test_cases.split(',')
                total_tests = submitted_test_cases_count.reduce(first_test_count) do |total, set|
                  sequence_test_count = test_set.test_case_by_id(set).sequence.test_count(@instance.module)
                  total + sequence_test_count
                end

                sequence_result = sequence.resume(request, headers, request.params, @error_message) do
                  count += 1
                  out << js_update_result(
                    instance: @instance,
                    sequence: sequence,
                    test_set: test_set,
                    set_count: count,
                    count: count,
                    total: total_tests
                  )
                  @instance.save!
                end
                all_test_cases << test_case.id
                failed_test_cases << test_case.id if sequence_result.fail?
                @instance.sequence_results.push(sequence_result)
                @instance.save!

                submitted_test_cases = sequence_result.next_test_cases.split(',')

                next_test_case = submitted_test_cases.shift
                finished = next_test_case.nil?
                if sequence_result.redirect_to_url
                  out << js_redirect_modal(sequence_result.redirect_to_url, sequence_result, @instance)
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

                  @instance.reload # ensure that we have all the latest data
                  sequence = test_case.sequence.new(@instance, client, settings.disable_tls_tests)
                  count = 0
                  sequence_result = sequence.start do
                    test_count += 1
                    count += 1
                    out << js_update_result(
                      instance: @instance,
                      sequence: sequence,
                      test_set: test_set,
                      set_count: count,
                      count: test_count,
                      total: total_tests
                    )
                  end
                  all_test_cases << test_case.id
                  failed_test_cases << test_case.id if sequence_result.fail?

                  sequence_result.test_set_id = test_set.id
                  sequence_result.test_case_id = test_case.id

                  sequence_result.next_test_cases = ([next_test_case] + submitted_test_cases).join(',')

                  sequence_result.save!
                  if sequence_result.redirect_to_url
                    out << js_redirect_modal(sequence_result.redirect_to_url, sequence_result, @instance)
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

                out << js_redirect("#{base_path}/#{@instance.id}/test_sets/#{test_set.id}/##{query_target}") if finished
              end
            else
              latest_sequence_result = Inferno::SequenceResult.find_by(testing_instance: @instance)
              test_set_id = latest_sequence_result&.test_set_id || @instance.module.default_test_set
              redirect "#{BASE_PATH}/#{@instance.id}/test_sets/#{test_set_id}/?error=no_#{params[:endpoint]}"
            end
          end
        end
      end
    end
  end
end
