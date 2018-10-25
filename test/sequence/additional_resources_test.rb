require File.expand_path '../../test_helper.rb', __FILE__

class AdditionalResourcesSequenceTest < MiniTest::Test

  REQUEST_HEADERS = { 'Accept'=>'application/json+fhir',
                      'Accept-Charset'=>'UTF-8',
                      'Content-Type'=>'application/json+fhir;charset=UTF-8'
                     }
  RESPONSE_HEADERS = {'content-type'=>'application/json+fhir'}

  def setup

    # additional_resources_bundle.json is a Bundle containing the example
    # Provenance and Composition from:
    # https://www.hl7.org/fhir/DSTU2/composition-example.json.html
    # https://www.hl7.org/fhir/DSTU2/provenance-example.json.html
    # The only changes made from these example resources are including them in
    # the same Bundle resource, making them reference the same patient, and
    # adding a period end field to the Provenance
    @bundle = FHIR::DSTU2.from_contents(load_fixture(:additional_resources_bundle))
    @composition = get_resources_from_bundle(@bundle, 'Composition').first
    @composition_bundle = wrap_resources_in_bundle([@composition])
    @provenance = get_resources_from_bundle(@bundle, 'Provenance').first
    @provenance_bundle = wrap_resources_in_bundle([@provenance])

    @composition_bundle.entry.each do |entry|
      entry.resource.meta = FHIR::DSTU2::Meta.new unless entry.resource.meta
      entry.resource.meta.versionId = '1'
    end
    @provenance_bundle.entry.each do |entry|
      entry.resource.meta = FHIR::DSTU2::Meta.new unless entry.resource.meta
      entry.resource.meta.versionId = '1'
    end

    @instance = Inferno::Models::TestingInstance.new(url: 'http://www.example.com',
                                   client_name: 'Inferno',
                                   base_url: 'http://localhost:4567',
                                   client_endpoint_key: Inferno::SecureRandomBase62.generate(32),
                                   client_id: SecureRandom.uuid,
                                   oauth_authorize_endpoint: 'http://oauth_reg.example.com/authorize',
                                   oauth_token_endpoint: 'http://oauth_reg.example.com/token',
                                   scopes: 'launch openid patient/*.* profile',
                                   token: JSON::JWT.new({iss: 'foo'}) #dummy token
                                   )

    # for these tests to work, the patient_id at @composition.subject.reference
    # and @provenance.target.reference should be identical
    @patient_id = @composition.subject.reference
    @patient_id = @patient_id.split('/')[-1] if @patient_id.include?('/')
    @instance.resource_references << Inferno::Models::ResourceReference.new({
    resource_type: 'Patient',
    resource_id: @patient_id
    })

    @instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.
    client = FHIR::Client.new(@instance.url)
    client.use_dstu2
    client.default_json
    @sequence = Inferno::Sequence::AdditionalResourcesSequence.new(@instance, client)
  end

  def test_all_pass
    WebMock.reset!

    # Search resources
    uri_template = Addressable::Template.new "http://www.example.com/Composition{?patient,type,period}"
    stub_request(:get, uri_template).
      with(headers: REQUEST_HEADERS).
      to_return(
        # Reject requests without authorization, then accept subsequent requests
        {status: 406, body: nil, headers: RESPONSE_HEADERS},
        {status: 200, body: @composition_bundle.to_json, headers: RESPONSE_HEADERS}
      )
    uri_template = Addressable::Template.new "http://www.example.com/Provenance{?patient,target,start,end,userid,agent}"
    stub_request(:get, uri_template).
      with(headers: REQUEST_HEADERS).
      to_return(
        # Reject requests without authorization, then accept subsequent requests
        {status: 406, body: nil, headers: RESPONSE_HEADERS},
        {status: 200, body: @provenance_bundle.to_json, headers: RESPONSE_HEADERS}
      )
    # read resources
    stub_request(:get, "http://www.example.com/Composition/#{@composition.id}").
      with(headers: REQUEST_HEADERS).
      to_return { |request|
        id = request.headers['Id']
        resourceType = request.headers['Resource'].split('::').last
        result = get_resources_from_bundle(@bundle,resourceType).find{|r|r.id==id}
        {status: 200, body: result.to_json, headers: RESPONSE_HEADERS}
      }
    stub_request(:get, "http://www.example.com/Provenance/#{@provenance.id}").
      with(headers: REQUEST_HEADERS).
      to_return { |request|
        id = request.headers['Id']
        resourceType = request.headers['Resource'].split('::').last
        result = get_resources_from_bundle(@bundle,resourceType).find{|r|r.id==id}
        {status: 200, body: result.to_json, headers: RESPONSE_HEADERS}
      }
    # history should return a history bundle
    stub_request(:get, "http://www.example.com/Composition/#{@composition.id}/_history").
      with(headers: REQUEST_HEADERS).
      to_return { |request|
        id = request.headers['Id']
        resourceType = request.headers['Resource'].split('::').last
        results = get_resources_from_bundle(@bundle,resourceType).find{|r|r.id==id}
        results = wrap_resources_in_bundle([results])
        results.type = 'history'
        {status: 200, body: results.to_json, headers: RESPONSE_HEADERS}
      }
    stub_request(:get, "http://www.example.com/Provenance/#{@provenance.id}/_history").
      with(headers: REQUEST_HEADERS).
      to_return { |request|
        id = request.headers['Id']
        resourceType = request.headers['Resource'].split('::').last
        results = get_resources_from_bundle(@bundle,resourceType).find{|r|r.id==id}
        results = wrap_resources_in_bundle([results])
        results.type = 'history'
        {status: 200, body: results.to_json, headers: RESPONSE_HEADERS}
      }
    # vread should return an instance
    stub_request(:get, "http://www.example.com/Composition/#{@composition.id}/_history/1").
      with(headers: REQUEST_HEADERS).
      to_return { |request|
        id = request.headers['Id']
        resourceType = request.headers['Resource'].split('::').last
        result = get_resources_from_bundle(@bundle,resourceType).find{|r|r.id==id}
        {status: 200, body: result.to_json, headers: RESPONSE_HEADERS}
      }
    stub_request(:get, "http://www.example.com/Provenance/#{@provenance.id}/_history/1").
      with(headers: REQUEST_HEADERS).
      to_return { |request|
        id = request.headers['Id']
        resourceType = request.headers['Resource'].split('::').last
        result = get_resources_from_bundle(@bundle,resourceType).find{|r|r.id==id}
        {status: 200, body: result.to_json, headers: RESPONSE_HEADERS}
      }

    sequence_result = @sequence.start
    failures = sequence_result.test_results.select{|r| r.result != 'pass'}
    assert failures.length == 0, "All tests should pass.  First error: #{!failures.empty? && failures.first.message}"
    assert sequence_result.result == 'pass', 'Sequence should pass'
    assert sequence_result.test_results.all?{|r| r.test_warnings.empty? }, 'There should not be any warnings.'
  end

  def get_resources_from_bundle(bundle,resourceType)
    resources = []
    bundle.entry.each do |entry|
      resources << entry.resource if entry.resource.resourceType == resourceType
    end
    resources
  end

  def wrap_resources_in_bundle(resources)
    bundle = FHIR::DSTU2::Bundle.new({'id': 'foo', 'type': 'searchset'})
    resources.each do |resource|
      bundle.entry << FHIR::DSTU2::Bundle::Entry.new
      bundle.entry.last.resource = resource
    end
    bundle
  end

end
