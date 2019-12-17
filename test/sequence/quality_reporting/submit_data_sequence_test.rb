# frozen_string_literal: true

require File.expand_path '../../test_helper.rb', __dir__

class SubmitDataSequenceTest < MiniTest::Test
  def setup
    @instance = Inferno::Models::TestingInstance.new(url: 'http://www.example.com', selected_module: 'quality_reporting')
    @instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.
    client = FHIR::Client.new(@instance.url)
    client.use_stu3
    client.default_json
    @sequence = Inferno::Sequence::SubmitDataSequence.new(@instance, client, true)
  end

  def test_all_pass
    WebMock.reset!

    stub_request(:post, /Measure/)
      .to_return(status: 200)

    stub_request(:get, /example/)
      .to_return(status: 200)

    sequence_result = @sequence.start
    assert sequence_result.pass?, 'The sequence should be marked as pass.'
    assert sequence_result.test_results.all? { |r| r.pass? || r.skip? }, 'All tests should pass'
  end

  def test_submit_data_fail
    WebMock.reset!

    stub_request(:post, /Measure/)
      .to_return(status: 400)

    sequence_result = @sequence.start
    assert(sequence_result.fail?, 'The sequence should be marked as fail.')
  end

  def test_resource_verify_fail
    WebMock.reset!

    stub_request(:post, /Measure/)
      .to_return(status: 200)

    stub_request(:get, /example/)
      .to_return(status: 404)

    sequence_result = @sequence.start
    assert(sequence_result.fail?, 'The sequence should be marked as fail')
  end
end
