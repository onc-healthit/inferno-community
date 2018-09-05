require 'yaml'
require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/namespace'
require 'fhir_client'
require 'rest-client'
require 'time_difference'
require 'pry'
require 'dm-core'
require 'dm-migrations'
require 'jwt'
require 'json/jwt'
require 'kramdown'

config_file './config.yml'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE if settings.disable_verify_peer

DEFAULT_SCOPES = settings.default_scopes
BASE_PATH = "/#{settings.base_path.gsub(/[^0-9a-z_-]/i, '')}"

DataMapper::Logger.new($stdout, :debug) if settings.environment == :development
DataMapper::Model.raise_on_save_failure = true

DataMapper.setup(:default, "sqlite3:data/#{settings.environment.to_s}_data.db")

require './lib/sequence_base'
['lib', 'models'].each do |dir|
  Dir.glob(File.join(File.dirname(File.absolute_path(__FILE__)),dir, '**','*.rb')).each do |file|
    require file
  end
end

require './lib/version'

DataMapper.finalize

[TestingInstance, SequenceResult, TestResult, TestWarning, RequestResponse, RequestResponseTestResult, SupportedResource, ResourceReference].each do |model|
  if settings.purge_database_on_reload || settings.environment == :test
    model.auto_migrate!
  else
    model.auto_upgrade!
  end
end

helpers do
  def request_headers
    env.inject({}){|acc, (k,v)| acc[$1.downcase] = v if k =~ /^http_(.*)/i; acc}
  end
  def version
    VERSION
  end
  def app_name
    settings.app_name
  end
  def valid_json?(json)
    JSON.parse(json)
    return true
  rescue JSON::ParserError => e
    return false
  end
  def tls_testing_supported?
    TlsTester.testing_supported?
  end
  def show_tutorial
    settings.show_tutorial
  end

  def js_hide_wait_modal
    "<script>console.log('hide_wait_modal');$('#WaitModal').modal('hide');</script>"
  end
  def js_show_test_modal
    "<script>console.log('show_test_modal');$('#testsRunningModal').modal('show')</script>"
  end
  def js_stayalive(time)
    "<script>console.log('Time running: ' + #{time})</script>"
  end
  def js_update_result(sequence, result, count, total)
    "<script>console.log('js_update_result');$('#testsRunningModal').find('.number-complete:last').html('(#{count} of #{total} #{sequence.class.title} tests complete)');</script>"
  end
  def js_redirect(location)
    "<script>console.log('js_window_location'); window.location = '#{location}'</script>"
  end
  def js_redirect_modal(location)
    "<script>console.log('js_redirect_modal');$('#testsRunningModal').find('.modal-body').html('Redirecting to <textarea readonly class=\"form-control\" rows=\"3\">#{location}</textarea>');</script>"
  end
  def js_next_sequence(sequences)
    # "<script>console.log('js_next_sequence');$('#testsRunningModal').find('.number-complete-container').append('<div class=\'number-complete\'></div>');</script>"
  end

  def markdown_to_html(markdown)
    # we need to remove the 'normal' level of indentation before passing to markdown editor
    # find the minimum non-zero spacing indent and reduce by that many for all lines (note, did't make work for tabs)
    natural_indent = markdown.lines.collect{|l| l.index(/[^ ]/)}.select{|l| !l.nil? && l> 0}.min || 0
    unindented_markdown = markdown.lines.map{|l| l[natural_indent..-1] || "\n"}.join

    Kramdown::Document.new(unindented_markdown).to_html
  end
end

get '/' do
  status, headers, body = call! env.merge("PATH_INFO" => BASE_PATH)
end

get '/landing/?' do
  # Custom landing page intended to be overwritten for branded deployments
  erb :landing
end

namespace BASE_PATH do
  get '/?' do
    erb :index
  end

  get '/static/*' do
    status, headers, body = call! env.merge("PATH_INFO" => '/' + params['splat'].first)
  end

  get '/:id/?' do
    instance = TestingInstance.get(params[:id])
    halt 404 if instance.nil?
    sequence_results = instance.latest_results
    erb :details, {}, {instance: instance, sequences: SequenceBase.ordered_sequences, sequence_results: sequence_results, error_code: params[:error]}
  end

  post '/?' do
    url = params['fhir_server']
    url = url.chomp('/') if url.end_with?('/')
    @instance = TestingInstance.new(url: url, name: params['name'], base_url: request.base_url)
    @instance.save!
    redirect "#{BASE_PATH}/#{@instance.id}/"
  end

  get '/:id/test_result/:test_result_id/?' do
    @test_result = TestResult.get(params[:test_result_id])
    halt 404 if @test_result.sequence_result.testing_instance.id != params[:id]
    erb :test_result_details, layout: false
  end

  get '/:id/sequence_result/:sequence_result_id/cancel' do

    @sequence_result = SequenceResult.get(params[:sequence_result_id])
    halt 404 if @sequence_result.testing_instance.id != params[:id]

    @sequence_result.result = 'cancel'
    cancel_message = 'Test cancelled by user.'

    if @sequence_result.test_results.length > 0
      last_result = @sequence_result.test_results.last
      last_result.result = 'cancel'
      last_result.message = cancel_message
    end

    sequence = SequenceBase.subclasses.find{|x| x.to_s.start_with?(@sequence_result.name)}

    current_test_count = @sequence_result.test_results.length

    sequence.tests.each_with_index do |test, index|
      next if index < current_test_count
      @sequence_result.test_results << TestResult.new(test_id: test[:test_id],
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
    instance = TestingInstance.get(params[:id])
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
                                sequences: SequenceBase.ordered_sequences,
                                sequence_results: instance.latest_results,
                                tests_running: true
                               })

      next_sequence = submitted_sequences.shift

      klass = nil
      klass = SequenceBase.subclasses.find{|x| x.to_s.start_with?(next_sequence)} if next_sequence

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
          out << js_redirect_modal(sequence_result.redirect_to_url)
          out << js_redirect(sequence_result.redirect_to_url)
        elsif  submitted_sequences.count > 0
          out << js_next_sequence(sequence_result.next_sequences)
        else
          finished = true
        end

        next_sequence = submitted_sequences.shift

        klass = nil
        klass = SequenceBase.subclasses.find{|x| x.to_s.start_with?(next_sequence)} if next_sequence
      end

      out << js_redirect("#{BASE_PATH}/#{params[:id]}/##{params[:sequence]}") if finished

    end

  end

  get '/:id/:key/:endpoint/?' do
    instance = TestingInstance.get(params[:id])
    halt 404 unless !instance.nil? && instance.client_endpoint_key == params[:key] && ['launch','redirect'].include?(params[:endpoint])

    sequence_result = instance.waiting_on_sequence

    if sequence_result.nil? || sequence_result.result != 'wait'
      redirect "/#{BASE_PATH}/#{params[:id]}/?error=no_#{params[:endpoint]}"
    else
      klass = SequenceBase.subclasses.find{|x| x.to_s.start_with?(sequence_result.name)}

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
                                  sequences: SequenceBase.ordered_sequences,
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
          out << js_redirect_modal(sequence_result.redirect_to_url)
          out << js_redirect(sequence_result.redirect_to_url)
        else
          out << js_redirect("#{BASE_PATH}/#{params[:id]}/##{params[:sequence]}")
        end
      end
    end
  end
end
