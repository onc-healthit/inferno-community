# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __dir__

class ArgonautQueryTest < MiniTest::Test
  REQUEST_HEADERS = { 'Accept' => 'application/json+fhir',
                      'Accept-Charset' => 'UTF-8',
                      'Content-Type' => 'application/json+fhir;charset=UTF-8' }.freeze
  RESPONSE_HEADERS = { 'content-type' => 'application/json+fhir' }.freeze

  def setup
    skip 'This test must be updated now that argo tests are broken out' # FIXME
    @conformance = FHIR::DSTU2.from_contents(load_fixture(:conformance_statement))
    @bundle = FHIR::DSTU2.from_contents(load_fixture(:sample_record))
    @bundle.entry.each do |entry|
      entry.resource.meta = FHIR::DSTU2::Meta.new unless entry.resource.meta
      entry.resource.meta.versionId = '1'
    end
    @patient_id = get_resources_from_bundle(@bundle, 'Patient').first.id

    @instance = Inferno::Models::TestingInstance.new(url: 'http://www.example.com',
                                                     client_name: 'Inferno',
                                                     base_url: 'http://localhost:4567',
                                                     client_endpoint_key: Inferno::SecureRandomBase62.generate(32),
                                                     client_id: SecureRandom.uuid,
                                                     oauth_authorize_endpoint: 'http://oauth_reg.example.com/authorize',
                                                     oauth_token_endpoint: 'http://oauth_reg.example.com/token',
                                                     scopes: 'launch openid patient/*.* profile')
    @instance.save_supported_resources(@conformance)
    @instance.resource_references << Inferno::Models::ResourceReference.new(
      resource_type: 'Patient',
      resource_id: @patient_id
    )
    @instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.
    client = FHIR::Client.new(@instance.url)
    client.use_dstu2
    client.default_json
    @sequence = Inferno::Sequence::ArgonautDataQuerySequence.new(@instance, client)
    @standalone_token_exchange = load_json_fixture(:standalone_token_exchange)
  end

  def test_all_pass
    skip 'This test must be updated now that argo tests are broken out' # FIXME
    WebMock.reset!

    patient = get_resources_from_bundle(@bundle, 'Patient').first
    # Reject requests without authorization, then accept subsequent requests
    stub_request(:get, "http://www.example.com/Patient/#{@patient_id}")
      .with(headers: REQUEST_HEADERS)
      .to_return(
        { status: 406, body: nil, headers: RESPONSE_HEADERS },
        status: 200, body: patient.to_json, headers: RESPONSE_HEADERS
      )

    patient_bundle = wrap_resources_in_bundle([patient])
    # Search Patient
    uri_template = Addressable::Template.new 'http://www.example.com/Patient{?identifier,family,gender,given,birthdate}'
    stub_request(:get, uri_template)
      .with(headers: REQUEST_HEADERS)
      .to_return(
        { status: 406, body: nil, headers: RESPONSE_HEADERS },
        status: 200, body: patient_bundle.to_json, headers: RESPONSE_HEADERS
      )

    # Patient history
    patient_history_bundle = wrap_resources_in_bundle([patient])
    patient_history_bundle.type = 'history'
    uri_template = Addressable::Template.new "http://www.example.com/Patient/#{@patient_id}/_history"
    stub_request(:get, uri_template)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 200, body: patient_history_bundle.to_json, headers: RESPONSE_HEADERS)

    uri_template = Addressable::Template.new "http://www.example.com/Patient/#{@patient_id}/_history/1"
    stub_request(:get, uri_template)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 200, body: patient.to_json, headers: RESPONSE_HEADERS)

    # Search resources
    resources = [
      'AllergyIntolerance', 'CarePlan', 'Condition', 'Device',
      'DiagnosticReport', 'DocumentReference', 'Goal', 'Immunization',
      'MedicationStatement', 'MedicationOrder', 'Observation', 'Procedure'
    ]
    resources.each do |resourceType|
      bundle = wrap_resources_in_bundle(get_resources_from_bundle(@bundle, resourceType))
      uri_template = Addressable::Template.new "http://www.example.com/#{resourceType}{?patient,category,status,clinicalstatus}"
      stub_request(:get, uri_template)
        .with(headers: REQUEST_HEADERS)
        .to_return(
          { status: 406, body: nil, headers: RESPONSE_HEADERS },
          status: 200, body: bundle.to_json, headers: RESPONSE_HEADERS
        )
      uri_template = Addressable::Template.new "http://www.example.com/#{resourceType}/{id}"
      stub_request(:get, uri_template).to_return do |request|
        id = request.headers['Id']
        resourceType = request.headers['Resource'].split('::').last
        result = get_resources_from_bundle(@bundle, resourceType).find { |r| r.id == id }
        { status: 200, body: result.to_json, headers: RESPONSE_HEADERS }
      end
      # history should return a history bundle
      uri_template = Addressable::Template.new "http://www.example.com/#{resourceType}/{id}/_history"
      stub_request(:get, uri_template).to_return do |request|
        id = request.headers['Id']
        resourceType = request.headers['Resource'].split('::').last
        results = get_resources_from_bundle(@bundle, resourceType).find { |r| r.id == id }
        results = wrap_resources_in_bundle([results])
        results.type = 'history'
        { status: 200, body: results.to_json, headers: RESPONSE_HEADERS }
      end
      # vread should return an instance
      uri_template = Addressable::Template.new "http://www.example.com/#{resourceType}/{id}/_history/1"
      stub_request(:get, uri_template).to_return do |request|
        id = request.headers['Id']
        resourceType = request.headers['Resource'].split('::').last
        result = get_resources_from_bundle(@bundle, resourceType).find { |r| r.id == id }
        { status: 200, body: result.to_json, headers: RESPONSE_HEADERS }
      end
    end

    # Special stub for comma-separated query params
    bundle = wrap_resources_in_bundle(get_resources_from_bundle(@bundle, 'Condition'))
    uri_template = Addressable::Template.new "http://www.example.com/Condition?clinicalstatus=active,recurrance,remission&patient=#{@patient_id}"
    stub_request(:get, uri_template)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 200, body: bundle.to_json, headers: RESPONSE_HEADERS)

    # Special stub for queries with dates
    date = '2010-03-01T15:15:00-05:00'
    bundle = wrap_resources_in_bundle(get_resources_from_bundle(@bundle, 'DiagnosticReport'))
    uri_template = Addressable::Template.new "http://www.example.com/DiagnosticReport?category=LAB&date=#{date}&patient=#{@patient_id}"
    stub_request(:get, uri_template)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 200, body: bundle.to_json, headers: RESPONSE_HEADERS)
    uri_template = Addressable::Template.new "http://www.example.com/DiagnosticReport?category=LAB&code=57698-3&date=#{date}&patient=#{@patient_id}"
    stub_request(:get, uri_template)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 200, body: bundle.to_json, headers: RESPONSE_HEADERS)

    bundle = wrap_resources_in_bundle(get_resources_from_bundle(@bundle, 'Observation'))
    uri_template = Addressable::Template.new "http://www.example.com/Observation?category=laboratory&date=#{date}&patient=#{@patient_id}"
    stub_request(:get, uri_template)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 200, body: bundle.to_json, headers: RESPONSE_HEADERS)
    uri_template = Addressable::Template.new "http://www.example.com/Observation?category=laboratory&code=8302-2&date=#{date}&patient=#{@patient_id}"
    stub_request(:get, uri_template)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 200, body: bundle.to_json, headers: RESPONSE_HEADERS)
    uri_template = Addressable::Template.new "http://www.example.com/Observation?category=vital-signs&date=#{date}&patient=#{@patient_id}"
    stub_request(:get, uri_template)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 200, body: bundle.to_json, headers: RESPONSE_HEADERS)
    uri_template = Addressable::Template.new "http://www.example.com/Observation?category=vital-signs&code=8302-2&date=#{date}&patient=#{@patient_id}"
    stub_request(:get, uri_template)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 200, body: bundle.to_json, headers: RESPONSE_HEADERS)
    uri_template = Addressable::Template.new "http://www.example.com/Observation?code=72166-2&patient=#{@patient_id}"
    # TODO: filter to 72166-2
    stub_request(:get, uri_template)
      .with(headers: REQUEST_HEADERS)
      .to_return(
        { status: 406, body: nil, headers: RESPONSE_HEADERS },
        status: 200, body: bundle.to_json, headers: RESPONSE_HEADERS
      )
    uri_template = Addressable::Template.new "http://www.example.com/Observation?category=vital-signs&patient=#{@patient_id}"
    # TODO: filter to `vital-signs`
    stub_request(:get, uri_template)
      .with(headers: REQUEST_HEADERS)
      .to_return(
        { status: 406, body: nil, headers: RESPONSE_HEADERS },
        status: 200, body: bundle.to_json, headers: RESPONSE_HEADERS
      )

    date = '2010-08-09T16:15:00-04:00'
    bundle = wrap_resources_in_bundle(get_resources_from_bundle(@bundle, 'Procedure'))
    uri_template = Addressable::Template.new "http://www.example.com/Procedure?date=#{date}&patient=#{@patient_id}"
    stub_request(:get, uri_template)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 200, body: bundle.to_json, headers: RESPONSE_HEADERS)

    date = '2018-03-05T15:15:00-05:00'
    bundle = wrap_resources_in_bundle(get_resources_from_bundle(@bundle, 'CarePlan'))
    uri_template = Addressable::Template.new "http://www.example.com/CarePlan?category=assess-plan&date=#{date}&patient=#{@patient_id}&status=active"
    stub_request(:get, uri_template)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 200, body: bundle.to_json, headers: RESPONSE_HEADERS)
    uri_template = Addressable::Template.new "http://www.example.com/CarePlan?category=assess-plan&date=#{date}&patient=#{@patient_id}"
    stub_request(:get, uri_template)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 200, body: bundle.to_json, headers: RESPONSE_HEADERS)

    bundle = wrap_resources_in_bundle(get_resources_from_bundle(@bundle, 'DocumentReference'))
    uri_template = Addressable::Template.new "http://www.example.com/DocumentReference?patient=#{@patient_id}&period=#{date}"
    stub_request(:get, uri_template)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 200, body: bundle.to_json, headers: RESPONSE_HEADERS)
    bundle = wrap_resources_in_bundle(get_resources_from_bundle(@bundle, 'DocumentReference'))
    uri_template = Addressable::Template.new "http://www.example.com/DocumentReference?patient=#{@patient_id}&period=#{date}&type=34133-9"
    # TODO: filter to 34133-9
    stub_request(:get, uri_template)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 200, body: bundle.to_json, headers: RESPONSE_HEADERS)

    sequence_result = @sequence.start

    assert sequence_result.result = 'pass', 'Sequence did not pass all tests.'
    assert sequence_result.error_count == 0
    assert sequence_result.todo_count == 0
    assert sequence_result.skip_count == 0
  end

  def get_resources_from_bundle(bundle, resourceType)
    resources = []
    bundle.entry.each do |entry|
      resources << entry.resource if entry.resource.resourceType == resourceType
    end
    resources
  end

  def wrap_resources_in_bundle(resources)
    bundle = FHIR::DSTU2::Bundle.new('id': 'foo', 'type': 'searchset')
    resources.each do |resource|
      bundle.entry << FHIR::DSTU2::Bundle::Entry.new
      bundle.entry.last.resource = resource
    end
    bundle
  end
end
