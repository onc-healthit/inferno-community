# frozen_string_literal: true

require_relative '../test_helper'

# Tests for the Medication Order Sequence
# It makes sure all the sequences pass and ensures no duplicate resource references occur from multiple runs
class MedicationStatementSequenceTest < MiniTest::Test
  def setup
    @medication_statement = FHIR::DSTU2.from_contents(load_fixture(:medication_statement))

    @medication_statement_bundle = wrap_resources_in_bundle(@medication_statement)

    @medication_statement_bundle.entry.each do |entry|
      entry.resource.meta = FHIR::DSTU2::Meta.new unless entry.resource.meta
      entry.resource.meta.versionId = '1'
    end

    @medication_statement_bundle.link << FHIR::DSTU2::Bundle::Link.new(url: "http://www.example.com/#{@medication_statement.resourceType}?patient=pat1")

    @medication_reference = load_json_fixture(:medication_reference)

    @instance = get_test_instance

    @patient_id = @medication_statement.patient.reference
    @patient_id = @patient_id.split('/')[-1] if @patient_id.include?('/')

    @patient_resource = FHIR::DSTU2::Patient.new(id: @patient_id)
    @practitioner_resource = FHIR::DSTU2::Practitioner.new(id: 432)

    # Assume we already have a patient
    @instance.resource_references << Inferno::Models::ResourceReference.new(
      resource_type: 'Patient',
      resource_id: @patient_id
    )

    # Register that the server supports MedicationStatement
    @instance.supported_resources << Inferno::Models::SupportedResource.create(
      resource_type: 'MedicationStatement',
      testing_instance_id: @instance.id,
      supported: true,
      read_supported: true,
      vread_supported: true,
      search_supported: true,
      history_supported: true
    )

    @instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.

    client = get_client(@instance)

    @sequence = Inferno::Sequence::ArgonautMedicationStatementSequence.new(@instance, client)

    @request_headers = { 'Accept' => 'application/json+fhir',
                         'Accept-Charset' => 'utf-8',
                         'User-Agent' => 'Ruby FHIR Client',
                         'Authorization' => "Bearer #{@instance.token}" }
    @response_headers = { 'content-type' => 'application/json+fhir' }
  end

  def full_sequence_stubs
    WebMock.reset!
    # Return 401 if no Authorization Header
    stub_request(:get, @medication_statement_bundle.link.first.url).to_return(status: 401)

    # Search Resources
    uri_template = Addressable::Template.new 'http://www.example.com/MedicationStatement{?patient,target,start,end,userid,agent}'
    stub_request(:get, uri_template)
      .with(headers: @request_headers)
      .to_return(
        status: 200, body: @medication_statement_bundle.to_json, headers: @response_headers
      )

    # Read Resources
    stub_request(:get, "http://www.example.com/MedicationStatement/#{@medication_statement.id}")
      .with(headers: @request_headers)
      .to_return(status: 200,
                 body: @medication_statement.to_json,
                 headers: { content_type: 'application/json+fhir; charset=UTF-8' })

    # history should return a history bundle
    stub_request(:get, "http://www.example.com/MedicationStatement/#{@medication_statement.id}/_history")
      .with(headers: @request_headers)
      .to_return(status: 200,
                 body: wrap_resources_in_bundle(@medication_statement, type: 'history').to_json,
                 headers: { content_type: 'application/json+fhir; charset=UTF-8' })

    # vread should return an instance
    stub_request(:get, "http://www.example.com/MedicationStatement/#{@medication_statement.id}/_history/1")
      .with(headers: @request_headers)
      .to_return(status: 200,
                 body: @medication_statement.to_json,
                 headers: { content_type: 'application/json+fhir; charset=UTF-8' })

    # Return Medication from a reference
    stub_request(:get, %r{example.com/Medication/})
      .with(headers: {
              'Authorization' => "Bearer #{@instance.token}"
            })
      .to_return(status: 200,
                 body: @medication_reference.to_json,
                 headers: { content_type: 'application/json+fhir; charset=UTF-8' })

    # Stub Patient for Reference Resolution Tests
    stub_request(:get, %r{example.com/Patient/})
      .with(headers: {
              'Authorization' => "Bearer #{@instance.token}"
            })
      .to_return(status: 200,
                 body: @patient_resource.to_json,
                 headers: { content_type: 'application/json+fhir; charset=UTF-8' })

    # Stub Practitioner for Reference Resolution Tests
    stub_request(:get, %r{example.com/Practitioner/})
      .with(headers: {
              'Authorization' => "Bearer #{@instance.token}"
            })
      .to_return(status: 200,
                 body: @practitioner_resource.to_json,
                 headers: { content_type: 'application/json+fhir; charset=UTF-8' })
  end

  def test_all_pass
    full_sequence_stubs

    sequence_result = @sequence.start

    failures = sequence_result.failures
    assert failures.empty?, "All tests should pass.  First error: #{!failures.empty? && failures.first.message}"
    assert sequence_result.pass?, 'The sequence should be marked as pass.'
    assert sequence_result.test_results.all? { |r| r.test_warnings.empty? }, 'There should not be any warnings.'
  end

  def test_no_duplicate_orders
    # Setup WebMocks
    full_sequence_stubs

    # Run First Sequence
    sequence_result = @sequence.start
    sequence_result.save!

    # Create the second sequence
    second_instance = Inferno::Models::TestingInstance.get(@instance[:id])
    second_instance.patient_id = @patient_id
    client = get_client(second_instance)

    # Run the sequence again
    second_instance = Inferno::Models::TestingInstance.get(@instance[:id])
    second_instance.patient_id = @patient_id
    second_sequence = Inferno::Sequence::ArgonautMedicationStatementSequence.new(second_instance, client, true)
    second_sequence.start

    expected_reference_number = @medication_statement_bundle.entry.length + 1 # add one for the patient reference
    assert second_instance.resource_references.length == expected_reference_number,
           "There should only be #{expected_reference_number} reference resources..." \
           "but #{second_instance.resource_references.length} were found\n" \
           "They are: #{second_instance.resource_references.map do |reference|
             reference[:resource_type] + reference[:resource_id]
           end.join(', ')} \n" \
           'Check for duplicates.'
  end
end
