require_relative './utils/assertions'
class SequenceBase

  include Assertions

  STATUS = {
    pass: 'pass',
    fail: 'fail',
    error: 'error',
    todo: 'todo',
    wait: 'wait',
    skip: 'skip'
  }

  @@test_index = 0

  @@preconditions = {}
  @@titles = {}
  @@descriptions = {}
  @@test_metadata = {}

  @@modal_before_run = []
  @@buttonless = []

  def initialize(instance, client, sequence_result = nil)
    @client = client
    @instance = instance
    @client.set_bearer_token(@instance.token) unless (@client.nil? || @instance.nil? || @instance.token.nil?)
    @client.monitor_requests unless @client.nil?
    @sequence_result = sequence_result
    @test_warnings = []
  end

  def resume(request = nil, headers = nil, params = nil, &block)

    @params = params unless params.nil?

    @sequence_result.test_results.last.result = STATUS[:pass]

    unless request.nil?
      @sequence_result.test_results.last.request_responses << RequestResponse.new(
        direction: 'inbound',
        request_method: request.request_method.downcase,
        request_url: request.url,
        request_headers: headers.to_json,
        request_payload: request.body.read
      )
    end

    @sequence_result.result = STATUS[:pass]
    @sequence_result.wait_at_endpoint = nil
    @sequence_result.redirect_to_url = nil

    @sequence_result.save!

    start(&block)
  end

  def start
    if @sequence_result.nil?
      @sequence_result = SequenceResult.new(name: sequence_name, result: STATUS[:pass], testing_instance: @instance)
    end

    start_at = @sequence_result.test_results.length

    methods = self.methods.grep(/_test$/).sort
    methods.each_with_index do |test_method, index|
      next if index < start_at
      @client.requests = [] unless @client.nil?
      LoggedRestClient.clear_log
      result = self.method(test_method).call()

      unless @client.nil?
        @client.requests.each do |req|
          result.request_responses << RequestResponse.new(
            direction: 'outbound',
            request_method: req.request[:method],
            request_url: req.request[:url],
            request_headers: req.request[:headers].to_json,
            request_payload: req.request[:payload],
            response_code: req.response[:code],
            response_headers: req.response[:headers].to_json,
            response_body: req.response[:body])
        end
      end

      LoggedRestClient.requests.each do |req|
        result.request_responses << RequestResponse.new(
          direction: req[:direction],
          request_method: req[:request][:method].to_s,
          request_url: req[:request][:url],
          request_headers: req[:request][:headers].to_json,
          request_payload: req[:request][:payload].to_json,
          response_code: req[:response][:code],
          response_headers: req[:response][:headers].to_json,
          response_body: req[:response][:body])
      end

      yield result if block_given?

      @sequence_result.test_results << result

      if result.result == STATUS[:wait]
        @sequence_result.redirect_to_url = result.redirect_to_url
        @sequence_result.wait_at_endpoint = result.wait_at_endpoint
        break
      end
    end

    @sequence_result.passed_count = @sequence_result.todo_count = @sequence_result.failed_count = @sequence_result.error_count = @sequence_result.skip_count = 0
    @sequence_result.result = STATUS[:pass]

    @sequence_result.test_results.each do |result|
      case result.result
      when STATUS[:pass]
        @sequence_result.passed_count += 1
      when STATUS[:todo]
        @sequence_result.todo_count += 1
      when STATUS[:fail]
        @sequence_result.failed_count += 1
        @sequence_result.result = result.result unless @sequence_result.result == STATUS[:error]
      when STATUS[:error]
        @sequence_result.error_count += 1
        @sequence_result.result = result.result
      when STATUS[:skip]
        @sequence_result.skip_count += 1
      when STATUS[:wait]
        @sequence_result.result = result.result
      end
    end

    @sequence_result
  end

  def self.test_count
    self.new(nil,nil).test_count
  end

  def test_count
    self.methods.grep(/_test$/).length
  end


  def sequence_name
    self.class.sequence_name
  end

  def self.sequence_name
    self.name.split('::').last.split('Sequence').first
  end

  def self.title(title = nil)
    @@titles[self.sequence_name] = title unless title.nil?
    @@titles[self.sequence_name] || self.sequence_name
  end

  def self.description(description = nil)
    @@descriptions[self.sequence_name] = description unless description.nil?
    @@descriptions[self.sequence_name]
  end

  def self.tests
    @@test_metadata[self.sequence_name]
  end

  def self.modal_before_run
    @@modal_before_run << self.sequence_name
  end

  def self.modal_before_run?
    @@modal_before_run.include?(self.sequence_name)
  end

  def self.buttonless
    @@buttonless << self.sequence_name
  end

  def self.buttonless?
    @@buttonless.include?(self.sequence_name)
  end

  def self.preconditions(description, &block)
    @@preconditions[self.sequence_name] = {
      block: block,
      description: description
    }
  end

  def self.preconditions_description
    @@preconditions[self.sequence_name] && @@preconditions[self.sequence_name][:description]
  end

  def self.preconditions_met_for?(instance)

    return true unless @@preconditions.key?(self.sequence_name)

    block = @@preconditions[self.sequence_name][:block]
    self.new(instance,nil).instance_eval &block
  end

  def self.test(name, url = nil, description = nil, required = :required, &block)

    @@test_index += 1

    is_required = (required != :optional)

    test_index = @@test_index
    test_method = "#{@@test_index.to_s.rjust(4,"0")} #{name} test".downcase.tr(' ', '_').to_sym
    contents = block

    @@test_metadata[self.sequence_name] ||= []
    @@test_metadata[self.sequence_name] << { name: name, url: url, description: description, test_index: test_index, required: is_required}

    wrapped = -> () do
      @test_warnings, @links, @requires, @validates = [],[],[],[]
      result = TestResult.new(name: name, result: STATUS[:pass], url: url, description: description, test_index: test_index, required: is_required)
      begin

      instance_eval &block

      rescue AssertionException, ClientException => e
        if required == :optional
          @test_warnings << e.message
        else
          result.result = STATUS[:fail]
          result.message = e.message
        end

      rescue TodoException => e
        result.result = STATUS[:todo]
        result.message = e.message

      rescue WaitException => e
        result.result = STATUS[:wait]
        result.wait_at_endpoint = e.endpoint

      rescue RedirectException => e
        result.result = STATUS[:wait]
        result.wait_at_endpoint = e.endpoint
        result.redirect_to_url = e.url

      rescue SkipException => e
        result.result = STATUS[:skip]
        result.message = e.message

      rescue => e
        result.result = STATUS[:error]
        result.message = "Fatal Error: #{e.message}"
      end
      result.test_warnings = @test_warnings.map{ |w| TestWarning.new(message: w)} unless @test_warnings.empty?
      result
    end

    define_method test_method, wrapped
  end

  def todo(message = "")
    raise TodoException.new message
  end

  def skip(message = "")
    raise SkipException.new message
  end

  def wait_at_endpoint(endpoint)
    raise WaitException.new endpoint
  end

  def redirect(url, endpoint)
    raise RedirectException.new url, endpoint
  end

  def warning
    begin
      yield
    rescue AssertionException => e
      @test_warnings << e.message
    end
  end

  def get_resource_by_params(klass, params = {})
    assert !params.empty?, "No params for search"
    options = {
      :search => {
        :flag => false,
        :compartment => nil,
        :parameters => params
      }
    }
    @client.search(klass, options)
  end

  def check_sort_order(entries)
    relevant_entries = entries.select{|x|x.request.try(:local_method)!='DELETE'}
    relevant_entries.map!(&:resource).map!(&:meta).compact rescue assert(false, 'Unable to find meta for resources returned by the bundle')

    relevant_entries.each_cons(2) do |left, right|
      if !left.versionId.nil? && !right.versionId.nil?
        assert (left.versionId > right.versionId), 'Result contains entries in the wrong order.'
      elsif !left.lastUpdated.nil? && !right.lastUpdated.nil?
        assert (left.lastUpdated >= right.lastUpdated), 'Result contains entries in the wrong order.'
      else
        raise AssertionException.new 'Unable to determine if entries are in the correct order -- no meta.versionId or meta.lastUpdated'
      end
    end
  end

  def validate_search_reply(klass, reply)
    assert_response_ok(reply)
    assert_bundle_response(reply)

    entries = reply.resource.entry.select{ |entry| entry.resource.class == klass }
    assert entries.length > 0, 'No resources of this type were returned'

    if klass == FHIR::DSTU2::Patient
      assert !reply.resource.get_by_id(@instance.patient_id).nil?, 'Server returned nil patient'
      assert reply.resource.get_by_id(@instance.patient_id).equals?(@patient, ['_id', "text", "meta", "lastUpdated"]), 'Server returned wrong patient'
    elsif [FHIR::DSTU2::CarePlan, FHIR::DSTU2::Goal, FHIR::DSTU2::DiagnosticReport, FHIR::DSTU2::Observation, FHIR::DSTU2::Procedure, FHIR::DSTU2::DocumentReference].include?(klass)
      entries.each do |entry|
        assert (entry.resource.subject && entry.resource.subject.reference.include?(@instance.patient_id)), "Subject on resource does not match patient requested"
      end
    else
      entries.each do |entry|
        assert (entry.resource.patient && entry.resource.patient.reference.include?(@instance.patient_id)), "Patient on resource does not match patient requested"
      end
    end
  end

  def validate_read_reply(resource, klass)
    assert !resource.nil?, "No #{klass.name.split(':').last} resources available from search."
    id = resource.try(:id)
    assert !id.nil?, "#{klass} id not returned"
    read_response = @client.read(klass, id)
    assert_response_ok read_response
    assert !read_response.resource.nil?, "Expected valid #{klass} resource to be present"
    assert read_response.resource.is_a?(klass), "Expected resource to be valid #{klass}"
  end

  def validate_history_reply(resource, klass)
    assert !resource.nil?, "No #{klass.name.split(':').last} resources available from search."
    id = resource.try(:id)
    assert !id.nil?, "#{klass} id not returned"
    history_response = @client.resource_instance_history(klass, id)
    assert_response_ok history_response
    assert_bundle_response history_response
    assert_equal "history", history_response.try(:resource).try(:type)
    entries = history_response.try(:resource).try(:entry)
    assert entries, 'No bundle entries returned'
    assert entries.try(:length) > 0, 'No resources of this type were returned'
    check_sort_order entries
  end

  def validate_vread_reply(resource, klass)
    assert !resource.nil?, "No #{klass.name.split(':').last} resources available from search."
    id = resource.try(:id)
    assert !id.nil?, "#{klass} id not returned"
    version_id = resource.try(:meta).try(:versionId)
    assert !version_id.nil?, "#{klass} version_id not returned"
    vread_response = @client.vread(klass, id, version_id)
    assert_response_ok vread_response
    assert !vread_response.resource.nil?, "Expected valid #{klass} resource to be present"
    assert vread_response.resource.is_a?(klass), "Expected resource to be valid #{klass}"
  end

  # This is intended to be called on SequenceBase
  # There is a test to ensure that this doesn't fall out of date
  def self.ordered_sequences
    [ ConformanceSequence,
        DynamicRegistrationSequence,
        PatientStandaloneLaunchSequence,
        ProviderEHRLaunchSequence,
        TokenIntrospectionSequence,
        ArgonautProfilesSequence,
        ArgonautDataQuerySequence,
        AdditionalResourcesSequence]
  end

end
