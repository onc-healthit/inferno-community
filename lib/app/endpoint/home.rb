module Inferno
  class App
    class Endpoint
      class Home < Endpoint

        set :prefix, '/inferno'

        get '/?' do
          erb :index
        end

        get '/static/*' do
          status, headers, body = call! env.merge("PATH_INFO" => '/' + params['splat'].first)
        end

        get '/:id/?' do
          instance = Inferno::Models::TestingInstance.get(params[:id])
          halt 404 if instance.nil?
          sequence_results = instance.latest_results
          erb :details, {}, {instance: instance,
                             sequences_groups: Inferno::Sequence::SequenceBase.sequences_groups,
                             sequences: Inferno::Sequence::SequenceBase.ordered_sequences,
                             sequence_results: sequence_results,
                             error_code: params[:error]}
        end

        post '/?' do
          url = params['fhir_server']
          url = url.chomp('/') if url.end_with?('/')
          @instance = Inferno::Models::TestingInstance.new(url: url, name: params['name'], base_url: request.base_url)
          @instance.save!
          redirect "#{BASE_PATH}/#{@instance.id}/"
        end

        get '/test_details/:sequence_name/:test_index?' do
          sequence = Inferno::Sequence::SequenceBase.subclasses.find{|x| x.name.demodulize.start_with?(params[:sequence_name])}
          halt 404 if !sequence
          @test_metadata = sequence.tests[params[:test_index].to_i]
          halt 404 if !@test_metadata
          erb :test_details, layout: false
        end

        get '/:id/test_result/:test_result_id/?' do
          @test_result = Inferno::Models::TestResult.get(params[:test_result_id])
          halt 404 if @test_result.sequence_result.testing_instance.id != params[:id]
          erb :test_result_details, layout: false
        end

        get '/:id/sequence_result/:sequence_result_id/cancel' do

          @sequence_result = Inferno::Models::SequenceResult.get(params[:sequence_result_id])
          halt 404 if @sequence_result.testing_instance.id != params[:id]

          @sequence_result.result = 'cancel'
          cancel_message = 'Test cancelled by user.'

          if @sequence_result.test_results.length > 0
            last_result = @sequence_result.test_results.last
            last_result.result = 'cancel'
            last_result.message = cancel_message
          end

          sequence = Inferno::Sequence::SequenceBase.subclasses.find{|x| x.name.demodulize.start_with?(@sequence_result.name)}

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

            redirect "#{BASE_PATH}/#{params[:id]}/##{@sequence_result.name}"
          end



          post '/:id/sequence_result/?' do
            instance = Inferno::Models::TestingInstance.get(params[:id])
            halt 404 if instance.nil?

            # Save params
            params[:required_fields].split(',').each do |field|
              instance.send("#{field}=", params[field]) if instance.respond_to? field
            end

            instance.save!

            client = FHIR::Client.new(instance.url)
            client.use_dstu2
            client.default_json
            submitted_sequences = params[:sequence].split(',')


            timer_count = 0;
            stayalive_timer_seconds = 20;

            finished = false
            stream :keep_open do |out|

              EventMachine::PeriodicTimer.new(stayalive_timer_seconds) do
                timer_count = timer_count + 1;
                out << js_stayalive(timer_count * stayalive_timer_seconds)
              end

              out << erb(:details, {}, {instance: instance,
                                        sequences_groups: Inferno::Sequence::SequenceBase.sequences_groups,
                                        sequences: Inferno::Sequence::SequenceBase.ordered_sequences,
                                        sequence_results: instance.latest_results,
                                        tests_running: true
              })

              next_sequence = submitted_sequences.shift

              klass = nil
              klass = Inferno::Sequence::SequenceBase.subclasses.find{|x| x.name.demodulize.start_with?(next_sequence)} if next_sequence

              while !klass.nil?

                out << js_show_test_modal

                sequence = klass.new(instance, client, settings.disable_tls_tests)
                count = 0
                sequence_result = sequence.start do |result|
                  count = count + 1
                  out << js_update_result(sequence,result, count, sequence.test_count)
                end

                sequence_result.next_sequences = submitted_sequences.join(',')

                sequence_result.save!
                if sequence_result.redirect_to_url
                  out << js_redirect_modal(sequence_result.redirect_to_url, sequence_result, instance)
                  # out << js_redirect(sequence_result.redirect_to_url)
                elsif  submitted_sequences.count > 0
                  out << js_next_sequence(sequence_result.next_sequences)
                else
                  finished = true
                end

                next_sequence = submitted_sequences.shift

                klass = nil
                klass = Inferno::Sequence::SequenceBase.subclasses.find{|x| x.name.demodulize.start_with?(next_sequence)} if next_sequence
              end

              out << js_redirect("#{BASE_PATH}/#{params[:id]}/##{params[:sequence]}") if finished

            end

          end

          get '/:id/:key/:endpoint/?' do
            instance = Inferno::Models::TestingInstance.get(params[:id])
            halt 404 unless !instance.nil? && instance.client_endpoint_key == params[:key] && ['launch','redirect'].include?(params[:endpoint])

            sequence_result = instance.waiting_on_sequence

            if sequence_result.nil? || sequence_result.result != 'wait'
              redirect "/#{BASE_PATH}/#{params[:id]}/?error=no_#{params[:endpoint]}"
            else
              klass = Inferno::Sequence::SequenceBase.subclasses.find{|x| x.name.demodulize.start_with?(sequence_result.name)}

              client = FHIR::Client.new(instance.url)
              client.use_dstu2
              client.default_json
              sequence = klass.new(instance, client, settings.disable_tls_tests, sequence_result)

              timer_count = 0;
              stayalive_timer_seconds = 20;

              stream do |out|

                EventMachine::PeriodicTimer.new(stayalive_timer_seconds) do
                  timer_count = timer_count + 1;
                  out << js_stayalive(timer_count * stayalive_timer_seconds)
                end

                out << erb(:details, {}, {instance: instance,
                                          sequences_groups: Inferno::Sequence::SequenceBase.sequences_groups,
                                          sequences: Inferno::Sequence::SequenceBase.ordered_sequences,
                                          sequence_results: instance.latest_results,
                                          tests_running: true}
                )

                out << js_hide_wait_modal
                out << js_show_test_modal
                count = sequence_result.test_results.length
                sequence_result = sequence.resume(request, headers, request.params) do |result|
                  count = count + 1
                  out << js_update_result(sequence,result, count, sequence.test_count)
                  instance.save!
                end
                instance.sequence_results.push(sequence_result)
                instance.save!
                if sequence_result.redirect_to_url
                  out << js_redirect_modal(sequence_result.redirect_to_url, sequence_result, instance)
                  # out << js_redirect(sequence_result.redirect_to_url)
                else
                  out << js_redirect("#{BASE_PATH}/#{params[:id]}/##{params[:sequence]}")
                end
              end
            end
          end
        end
      end
    end
  end
