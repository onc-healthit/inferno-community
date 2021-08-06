# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/app/models/testing_instance'
require_relative '../../lib/app/models/sequence_result'
require_relative '../../lib/app/models/test_result'

describe Inferno::RequestResponse do
  before do
    @instance = Inferno::TestingInstance.create(selected_module: 'uscore_v3.1.1')
    @instance_id = @instance.id
    @sequence_result = Inferno::SequenceResult.create(testing_instance: @instance)
    @result = Inferno::TestResult.new(sequence_result: @sequence_result)
    @result.save!
  end

  it 'returns the request and responses in the correct order' do
    10.times do |index|
      @result.request_responses << Inferno::RequestResponse.create(
        request_url: "http://#{index}"
      )
      @result.save!
    end

    instance = Inferno::TestingInstance.find(@instance_id)
    result = instance.sequence_results.first.test_results.first
    result.request_responses.each_with_index do |request_response, index|
      assert_equal request_response.request_url, "http://#{index}"
    end
  end

  it "doesn't raise an error when invalid headers are received" do
    bad_header = { 'abc' => (0..255).map(&:chr).join }

    request = Inferno::RequestResponse.from_request(
      OpenStruct.new(
        request: { headers: bad_header },
        response: {}
      ),
      'abc'
    )

    assert(request.request_headers.match?(/"ERROR":/))
  end
end
