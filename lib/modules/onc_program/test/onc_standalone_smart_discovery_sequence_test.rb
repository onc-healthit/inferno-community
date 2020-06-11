# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::OncStandaloneSMARTDiscoverySequence do
  before do
    @sequence_class = Inferno::Sequence::OncStandaloneSMARTDiscoverySequence
    @client = FHIR::Client.new('http://www.example.com/fhir')
    @instance = Inferno::Models::TestingInstance.new
  end

  describe 'required capabilities test' do
    before do
      @test = @sequence_class[:required_capabilities]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'skips if no well-known configuration was found' do
      @sequence.instance_variable_set(:@well_known_configuration, nil)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No well-known SMART configuration found.', exception.message
    end

    it 'fails if the capabilities are not an array' do
      @sequence.instance_variable_set(:@well_known_configuration, 'capabilities': 'abc')

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'The well-known capabilities are not an array', exception.message
    end

    it 'fails if a required capability is missing' do
      @sequence_class::REQUIRED_SMART_CAPABILITIES.each do |capability|
        capabilities = @sequence_class::REQUIRED_SMART_CAPABILITIES.dup
        capabilities.delete(capability)

        @sequence.instance_variable_set(:@well_known_configuration, 'capabilities' => capabilities)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal "The following required capabilities are missing: #{capability}", exception.message
      end
    end

    it 'succeeds if all required capabilities are present' do
      capabilities = @sequence_class::REQUIRED_SMART_CAPABILITIES
      @sequence.instance_variable_set(:@well_known_configuration, 'capabilities' => capabilities)

      @sequence.run_test(@test)
    end
  end
end

class OncSMARTDiscoveryTest < MiniTest::Test
  def setup
    instance = get_test_instance
    instance.url = 'bad'
    instance.onc_sl_url = 'http://www.example.com'
    client = get_client(instance)

    @sequence = Inferno::Sequence::OncStandaloneSMARTDiscoverySequence.new(instance, client)
  end

  def full_sequence_stubs
    base_url = 'http://www.example.com'
    smart_configuration = load_fixture(:smart_configuration)
    smart_metadata = load_fixture(:smart_metadata)

    stub_request(:get, "#{base_url}/metadata")
      .to_return(
        status: 200,
        body: smart_metadata,
        headers: { content_type: 'application/json+fhir; charset=UTF-8' }
      )

    stub_request(:get, "#{base_url}/.well-known/smart-configuration")
      .to_return(
        status: 200,
        body: smart_configuration,
        headers: { content_type: 'application/json; charset=UTF-8' }
      )
  end

  def test_all_pass
    WebMock.reset!
    full_sequence_stubs

    sequence_result = @sequence.start

    failures = sequence_result.failures
    assert failures.empty?, "All tests should pass. First error: #{!failures.empty? && failures.first.message}"
    assert sequence_result.pass?, "The sequence should be marked as pass. #{sequence_result.result}"
    assert sequence_result.test_results.all? { |r| r.test_warnings.empty? }, 'There should not be any warnings.'
  end
end
