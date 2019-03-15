# frozen_string_literal: true

require_relative '../test_helper'

# Tests for the Patient Read Sequence
# It makes sure all the sequences pass and ensures no duplicate resource references occur from multiple runs
class PatientSequenceTest < MiniTest::Test
  def setup
    @bundle = FHIR::DSTU2.from_contents(load_fixture(:sample_record))
    @patient = get_resources_from_bundle(@bundle,'Patient').first
    @instance = get_test_instance

    @patient_id = @patient.id
    @patient_id = @patient_id.split('/')[-1] if @patient_id.include?('/')

    # Assume we already have a patient
    @instance.resource_references << Inferno::Models::ResourceReference.new(
      resource_type: 'Patient',
      resource_id: @patient_id
    )

    @instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.

    client = get_client(@instance)

    @sequence = Inferno::Sequence::ArgonautPatientSequence.new(@instance, client)

    @request_headers = { 'Accept' => 'application/json+fhir',
                         'Accept-Charset' => 'utf-8',
                         'User-Agent' => 'Ruby FHIR Client',
                         'Authorization' => "Bearer #{@instance.token}" }

    @history_request_headers = {
        'Accept' => 'application/json+fhir',
        'Accept-Charset' => 'utf-8',
        'User-Agent' => 'Ruby FHIR Client',
        'Authorization' => "Bearer #{@instance.token}",
        'Host' => 'www.example.com',
        'Accept-Encoding'=>'gzip, deflate'
    }
    @response_headers = { 'content-type' => 'application/json+fhir' }
  end

  def full_sequence_stubs
    WebMock.reset!

    patient = get_resources_from_bundle(@bundle,'Patient').first
    # Reject requests without authorization, then accept subsequent requests
    uri_template = Addressable::Template.new "http://www.example.com/Patient{?identifier,family,gender,given,birthdate}"
    stub_request(:get, "http://www.example.com/Patient/#{@patient_id}").
      to_return(
        {status: 406, body: nil, headers: @response_headers},
        {status: 200, body: patient.to_json, headers: @response_headers}
      )

    stub_request(:get, uri_template).
      to_return(
        {status: 406, body: nil, headers: @response_headers},
        {status: 200, body: patient.to_json, headers: @response_headers}
      )

    patient_bundle = wrap_resources_in_bundle([patient])
    # Search Patient

    stub_request(:get, "http://www.example.com/Patient/#{@patient_id}").
      with(headers: @request_headers).
      to_return(
        {status: 200, body: patient.to_json, headers: @response_headers}
      )

    stub_request(:get, uri_template).
      with(headers: @request_headers).
      to_return(
        {status: 200, body: patient_bundle.to_json, headers: @response_headers}
      )

    # Patient history
    patient_history_bundle = wrap_resources_in_bundle([patient])
    patient_history_bundle.type = 'history'
    uri_template = Addressable::Template.new "http://www.example.com/Patient/#{@patient_id}/_history"
    stub_request(:get, uri_template).
      with(headers: @history_request_headers).
      to_return(status: 200, body: patient_history_bundle.to_json, headers: @response_headers)

    uri_template = Addressable::Template.new "http://www.example.com/Patient/#{patient_history_bundle.id}/_history/1"
    stub_request(:get, uri_template).
      with(headers: @history_request_headers).
      to_return(status: 200, body: patient.to_json, headers: @response_headers)

  end

  def test_all_pass
    full_sequence_stubs

    sequence_result = @sequence.start

    failures = sequence_result.test_results.select { |r| r.result != 'pass' && r.result != 'skip' }
    assert failures.empty?, "All tests should pass.  First error: #{!failures.empty? && failures.first.message}"
    assert sequence_result.result == 'pass', 'The sequence should be marked as pass.'
    assert sequence_result.test_results.all? { |r| r.test_warnings.empty? }, 'There should not be any warnings.'
  end
end
