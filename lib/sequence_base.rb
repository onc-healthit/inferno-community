require_relative './utils/assertions'
class SequenceBase

  include Assertions

  STATUS = {
    running: 'running',
    pass: 'pass',
    fail: 'fail',
    error: 'error',
    todo: 'todo',
    wait: 'wait',
  }

  @@test_index = 0
  @@modal_before_run = []
  @@buttonless = []
  @@child_test = []
  @@preconditions = {}

  def self.test_count
    self.new(nil,nil).test_count
  end

  def test_count
    self.methods.grep(/_test$/).length
  end

  def initialize(instance, client, sequence_result = nil)
    @client = client
    @instance = instance
    @client.set_bearer_token(@instance.token) unless (@client.nil? || @instance.nil? || @instance.token.nil?)
    @client.monitor_requests unless @client.nil?
    @sequence_result = sequence_result
    @warnings = []
  end

  def resume(params)

    @params = params
    @sequence_result.test_results.last.result = STATUS[:pass]
    @sequence_result.result = STATUS[:pass]
    @sequence_result.wait_at_endpoint = nil
    @sequence_result.redirect_to_url = nil

    start
  end

  def start
    if @sequence_result.nil?
      @sequence_result = SequenceResult.new(id: SecureRandom.uuid, name: sequence_name, result: STATUS[:pass])
    end

    start_at = @sequence_result.test_results.length
    puts "STARTING AT #{start_at}"

    methods = self.methods.grep(/_test$/).sort
    methods.each_with_index do |test_method, index|
      next if index < start_at
      @client.requests = [] unless @client.nil?
      result = self.method(test_method).call()

      unless @client.nil?
        @client.requests.each do |req|
          result.request_responses << RequestResponse.new(
            id: SecureRandom.uuid,
            request_method: req.request[:method],
            request_url: req.request[:url],
            request_headers: req.request[:headers].to_json,
            request_body: req.request[:body],
            response_code: req.response[:code],
            response_headers: req.response[:headers].to_json,
            response_body: req.response[:body])
        end
      end

      @sequence_result.test_results << result

      if result.result == STATUS[:wait]
        @sequence_result.redirect_to_url = result.redirect_to_url
        @sequence_result.wait_at_endpoint = result.wait_at_endpoint
        break
      end
    end

    @sequence_result.passed_count = @sequence_result.todo_count = @sequence_result.failed_count = @sequence_result.error_count = 0
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
      when STATUS[:wait]
        @sequence_result.result = result.result
      end
    end

    @sequence_result
  end

  def sequence_name
    self.class.sequence_name
  end

  def self.sequence_name
    self.name.split('::').last.split('Sequence').first
  end

  def self.description(description)
    define_method 'display', -> () {description}
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

  def self.child_test
    @@child_test << self.sequence_name
  end

  def self.child_test?
    @@child_test.include?(self.sequence_name)
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

  def self.test(name, url = nil, description = nil, &block)
    @@test_index += 1

    test_index = @@test_index
    test_method = "#{@@test_index.to_s.rjust(4,"0")} #{name} test".downcase.tr(' ', '_').to_sym
    contents = block

    wrapped = -> () do
      @warnings, @links, @requires, @validates = [],[],[],[]
      result = TestResult.new(id: SecureRandom.uuid, name: name, result: STATUS[:pass], url: url, description: description, test_index: test_index)
      begin
        instance_eval &block

        # result.update(t.status, t.message, t.data) if !t.nil? && t.is_a?(Crucible::Tests::TestResult)
      rescue AssertionException => e
        result.result = STATUS[:fail]
        result.message = e.message

      rescue TodoException => e
        result.result = STATUS[:todo]
        result.message = e.message

      rescue ClientException => e
        result.result = STATUS[:fail]
        result.message = e.message

      rescue WaitException => e
        result.result = STATUS[:wait]
        result.wait_at_endpoint = e.endpoint

      rescue RedirectException => e
        result.result = STATUS[:wait]
        result.wait_at_endpoint = e.endpoint
        result.redirect_to_url = e.url

      # rescue SkipException => e
      #   result.update(STATUS[:skip], "Skipped: #{e.message}", '')
      rescue => e
        result.result = STATUS[:error]
        result.message = "Fatal Error: #{e.message}"
      end
      # result.update(STATUS[:skip], "Skipped because setup failed.", "-") if @setup_failed
      result.warnings = @warnings.map{ |w| Warning.new(message: w)} unless @warnings.empty?
      # result.requires = @requires unless @requires.empty?
      # result.validates = @validates unless @validates.empty?
      # result.links = @links unless @links.empty?
      # result.id = key
      # result.code = contents.source
      # result.id = "#{result.id}_#{result_id_suffix}" if respond_to? :result_id_suffix # add the resource to resource based tests to make ids unique

      result
    end

    define_method test_method, wrapped
  end

  def todo(message = "")
    raise TodoException.new message
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
      @warnings << e.message
    end
  end
end

