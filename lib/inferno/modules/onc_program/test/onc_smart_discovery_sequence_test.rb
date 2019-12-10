# frozen_string_literal: true

require_relative '../../../../../test/test_helper'
class ONCSMARTDiscoveryTest < MiniTest::Test
  def setup
    instance = get_test_instance
    client = get_client(instance)

    @sequence = Inferno::Sequence::ONCSMARTDiscoverySequence.new(instance, client)
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
