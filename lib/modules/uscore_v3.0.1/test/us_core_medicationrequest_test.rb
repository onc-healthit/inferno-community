# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore301MedicationrequestSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore301MedicationrequestSequence
    @base_url = 'http://www.example.com/fhir'
    @client = FHIR::Client.new(@base_url)
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(token: @token)
    @patient_id = '123'
    @instance.patient_id = @patient_id
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'unauthorized search test' do
    before do
      @test = @sequence_class[:unauthorized_search]
      @sequence = @sequence_class.new(@instance, @client)

      @medicationrequest_ary = load_json_fixture(:us_core_medicationrequest_medicationrequest_ary)
        .map { |resource| FHIR.from_contents(resource.to_json) }
      @sequence.instance_variable_set(:'@medicationrequest_ary', @medicationrequest_ary)

      @query = {
        'patient': @instance.patient_id,
        'intent': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@medicationrequest_ary, 'intent'))
      }
    end

    it 'fails when the token refresh response has a success status' do
      stub_request(:get, "#{@base_url}/MedicationRequest")
        .with(query: @query)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 401, but found 200', exception.message
    end

    it 'succeeds when the token refresh response has an error status' do
      stub_request(:get, "#{@base_url}/MedicationRequest")
        .with(query: @query)
        .to_return(status: 401)

      @sequence.run_test(@test)
    end

    it 'is omitted when no token is set' do
      @instance.token = ''

      exception = assert_raises(Inferno::OmitException) { @sequence.run_test(@test) }

      assert_equal 'Do not test if no bearer token set', exception.message
    end
  end
end
