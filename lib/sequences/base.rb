require_relative './assertions'
class SequenceBase

  include Assertions

  STATUS = {
    pass: 'pass',
    fail: 'fail',
    error: 'error',
  }

  @@test_index = 0
  @@modal_before_run = []
  @@buttonless = []

  def self.test_count
    self.new(nil,nil).test_count
  end

  def test_count
    self.methods.grep(/_test$/).length
  end

  def initialize(instance, client)
    @client = client
    @instance = instance
    @client.set_bearer_token(@instance.token) unless (@client.nil? || @instance.nil? || @instance.token.nil?)
  end

  def start
    sequence_result = SequenceResult.new(id: SecureRandom.uuid, name: sequence_name, result: STATUS[:pass])
    methods = self.methods.grep(/_test$/).sort
    methods.each_with_index do |test_method, index|
      result = self.method(test_method).call()
      sequence_result.test_results << result
      case result.result
      when STATUS[:pass]
        sequence_result.passed_count += 1
      when STATUS[:fail]
        sequence_result.failed_count += 1
        sequence_result.result = result.result unless sequence_result.result == STATUS[:error]
      when STATUS[:error]
        sequence_result.error_count += 1
        sequence_result.result = result.result
      end
    end
    sequence_result
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

  def self.test(name, url = nil, description = nil, &block)
    @@test_index += 1

    test_method = "#{@@test_index.to_s.rjust(4,"0")} #{name} test".downcase.tr(' ', '_').to_sym
    contents = block
    wrapped = -> () do
      @warnings, @links, @requires, @validates = [],[],[],[]
      result = ""
      result = TestResult.new(id: SecureRandom.uuid, name: name, result: STATUS[:pass])
      begin
        t = instance_eval &block

        # result.update(t.status, t.message, t.data) if !t.nil? && t.is_a?(Crucible::Tests::TestResult)
      rescue AssertionException => e
        result.result = STATUS[:fail]
        result.message = e.message
      rescue SkipException => e
        # result.update(STATUS[:skip], "Skipped: #{e.message}", '')
      rescue ClientException => e
        result.result = STATUS[:fail]
        result.message = e.message
        # result.update(STATUS[:fail], e.message, '')
      rescue => e
        result.result = STATUS[:error]
        result.message = "Fatal Error: #{e.message}"
      end
      # result.update(STATUS[:skip], "Skipped because setup failed.", "-") if @setup_failed
      # result.warnings = @warnings unless @warnings.empty?
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
end
