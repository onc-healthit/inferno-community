# frozen_string_literal: true

require_relative '../../test_helper'
class CareTeamSequenceTest < MiniTest::Test
  def setup
    @instance = get_test_instance
    client = get_client(@instance)

    @fixture = 'care_team' # put fixture file name here
    @sequence = Inferno::Sequence::ArgonautCareTeamSequence.new(@instance, client) # put sequence here
    @resource_type = 'CarePlan'

    @resource = FHIR::DSTU2.from_contents(load_fixture(@fixture.to_sym))
    assert_empty @resource.validate, "Setup failure: Resource fixture #{@fixture}.json not a valid #{@resource_type}."

    @resource_bundle = wrap_resources_in_bundle(@resource)
    @resource_bundle.entry.each do |entry|
      entry.resource.meta = FHIR::DSTU2::Meta.new unless entry.resource.meta
      entry.resource.meta.versionId = '1'
    end

    @patient_id = @resource.subject.reference
    @patient_id = @patient_id.split('/')[-1] if @patient_id.include?('/')

    @patient_resource = FHIR::DSTU2::Patient.new(id: @patient_id)

    # Assume we already have a patient
    @instance.resource_references << Inferno::Models::ResourceReference.new(
      resource_type: 'Patient',
      resource_id: @patient_id
    )

    # Register that the server supports MedicationStatement
    if @instance.resource_references.none? { |r| r.resource_type == @resource_type }
      @instance.supported_resources << Inferno::Models::SupportedResource.create(
        resource_type: @resource_type.to_s,
        testing_instance_id: @instance.id,
        supported: true,
        read_supported: true,
        vread_supported: true,
        search_supported: true,
        history_supported: true
      )
    end

    @instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.

    @request_headers = { 'Accept' => 'application/json+fhir',
                         'Accept-Charset' => 'utf-8',
                         'User-Agent' => 'Ruby FHIR Client',
                         'Authorization' => "Bearer #{@instance.token}" }

    @extended_request_headers = { 'Accept' => 'application/json+fhir',
                                  'Accept-Charset' => 'utf-8',
                                  'User-Agent' => 'Ruby FHIR Client',
                                  'Accept-Encoding' => 'gzip, deflate',
                                  'Host' => 'www.example.com',
                                  'Authorization' => "Bearer #{@instance.token}" }

    @response_headers = { 'content-type' => 'application/json+fhir' }
  end

  def full_sequence_stubs
    # Return 401 if no Authorization Header
    uri_template = Addressable::Template.new "http://www.example.com/#{@resource_type}{?patient,category}"
    stub_request(:get, uri_template).to_return(status: 401)

    # Search Resources
    stub_request(:get, uri_template)
      .with(headers: @request_headers)
      .to_return(
        status: 200, body: @resource_bundle.to_json, headers: @response_headers
      )

    # Read Resources
    stub_request(:get, "http://www.example.com/#{@resource_type}/#{@resource.id}")
      .with(headers: @request_headers)
      .to_return(status: 200,
                 body: @resource.to_json,
                 headers: { content_type: 'application/json+fhir; charset=UTF-8' })

    # history should return a history bundle
    stub_request(:get, "http://www.example.com/#{@resource_type}/#{@resource.id}/_history")
      .with(headers: @extended_request_headers)
      .to_return(status: 200,
                 body: wrap_resources_in_bundle(@resource, type: 'history').to_json,
                 headers: { content_type: 'application/json+fhir; charset=UTF-8' })

    # vread should return an instance
    stub_request(:get, "http://www.example.com/#{@resource_type}/#{@resource.id}/_history/1")
      .with(headers: @extended_request_headers)
      .to_return(status: 200,
                 body: @resource.to_json,
                 headers: { content_type: 'application/json+fhir; charset=UTF-8' })

    # Stub Patient for Reference Resolution Tests
    stub_request(:get, %r{example.com/Patient/})
      .with(headers: {
              'Authorization' => "Bearer #{@instance.token}"
            })
      .to_return(status: 200,
                 body: @patient_resource.to_json,
                 headers: { content_type: 'application/json+fhir; charset=UTF-8' })
    stub_request(:get, %r{example.com/Practitioner/1})
      .with(headers: @extended_request_headers)
      .to_return(status: 200,
                 body: @patient_resource.to_json,
                 headers: { content_type: 'application/json+fhir; charset=UTF-8' })
  end

  def test_all_pass
    full_sequence_stubs

    sequence_result = @sequence.start

    failures = sequence_result.test_results.select { |r| r.result != 'pass' && r.result != 'skip' }
    assert failures.empty?, "All tests should pass.  First error: #{!failures.empty? && failures.first.message}"
    sequence_result.test_results.each do |test_result|
      assert test_result.result == 'pass', "#{test_result.name} - #{test_result.result}"
    end
    assert sequence_result.result == 'pass', "The sequence should be marked as pass. #{sequence_result.result}"
    assert sequence_result.test_results.all? { |r| r.test_warnings.empty? }, 'There should not be any warnings.'
  end
end
