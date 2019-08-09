# frozen_string_literal: true

module Inferno
  class App
    module TestSetEndpoints
      def self.included(klass)
        klass.class_eval do
          # Returns a specific testing instance test page
          get '/:id/test_sets/:test_set_id/?' do
            instance = Inferno::Models::TestingInstance.get(params[:id])
            halt 404 if instance.nil?
            test_set = instance.module.test_sets[params[:test_set_id].to_sym]
            halt 404 if test_set.nil?
            sequence_results = instance.latest_results_by_case

            erb(
              instance.module.view_by_test_set(params[:test_set_id]),
              {},
              instance: instance,
              test_set: test_set,
              sequence_results: sequence_results,
              error_code: params[:error]
            )
          end

          get '/:id/test_sets/:test_set_id/report?' do
            instance = Inferno::Models::TestingInstance.get(params[:id])
            halt 404 if instance.nil?
            test_set = instance.module.test_sets[params[:test_set_id].to_sym]
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
              final_result: instance.final_result(params[:test_set_id]),
              inferno_url: "#{request.base_url}#{base_path}/#{instance.id}/test_sets/#{params[:test_set_id]}/"
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

          # Cancels the currently running test
          get '/:id/test_sets/:test_set_id/sequence_result/:sequence_result_id/cancel' do
            sequence_result = Inferno::Models::SequenceResult.get(params[:sequence_result_id])
            halt 404 if sequence_result.testing_instance.id != params[:id]
            test_set = sequence_result.testing_instance.module.test_sets[params[:test_set_id].to_sym]
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

            current_test_count = sequence_result.result_count

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

            redirect "#{base_path}/#{params[:id]}/test_sets/#{params[:test_set_id]}/##{query_target}"
          end

          get '/:id/test_sets/:test_set_id/sequence_result?' do
            redirect "#{base_path}/#{params[:id]}/test_sets/#{params[:test_set_id]}/"
          end

          # Run a sequence and get the results
          post '/:id/test_sets/:test_set_id/sequence_result?' do
            instance = Inferno::Models::TestingInstance.get(params[:id])
            halt 404 if instance.nil?
            test_set = instance.module.test_sets[params[:test_set_id].to_sym]
            halt 404 if test_set.nil?

            cookies[:instance_id_test_set] = "#{instance.id}/test_sets/#{params[:test_set_id]}"

            # Save params
            params[:required_fields].split(',').each do |field|
              instance.send("#{field}=", params[field]) if instance.respond_to? field
            end

            instance.save!

            client = FHIR::Client.for_testing_instance(instance)
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

              out << erb(
                instance.module.view_by_test_set(params[:test_set_id]),
                {},
                instance: instance,
                test_set: test_set,
                sequence_results: instance.latest_results_by_case,
                tests_running: true,
                test_group: test_group.id
              )

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

              out << js_redirect("#{base_path}/#{params[:id]}/test_sets/#{params[:test_set_id]}/##{query_target}") if finished
            end
          end
        end
      end
    end
  end
end
