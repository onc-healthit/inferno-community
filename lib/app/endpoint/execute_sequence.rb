# frozen_string_literal: true

module Inferno
  class App
    class Endpoint
      # ExecuteSequence provides the test running specific code
      class ExecuteSequence < Endpoint
        # Set the url prefix these routes will map to
        set :prefix, BASE_PATH

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


        get '/:id/:test_set/:key/:endpoint/?' do
          instance = Inferno::Models::TestingInstance.get(params[:id])
          halt 404 unless !instance.nil? &&
                          instance.client_endpoint_key == params[:key] &&
                          %w[launch redirect].include?(params[:endpoint])
          test_set = instance.module.test_sets[params[:test_set].to_sym]
          halt 404 if test_set.nil?

          sequence_result = instance.waiting_on_sequence

          if sequence_result.nil? || sequence_result.result != 'wait'
            redirect "/#{BASE_PATH}/#{params[:id]}/?error=no_#{params[:endpoint]}"
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

              out << erb(instance.module.view_by_test_set(params[:test_set]), {}, instance: instance,
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
                       js_redirect("#{base_path}/#{params[:id]}/##{sequence_result.name}")
                     end
            end
          end
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

      end
    end
  end
end
