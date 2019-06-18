# frozen_string_literal: true

require_relative '../test_helper'

class R4ProvenanceSequenceTest < MiniTest::Test
  def setup
    @patient_id = 1234
    @provenance_resource = load_json_fixture(:provenance)
    provenance_url = "http://www.example.com/Provenance/#{@provenance_resource['id']}"
    @provenance_bundle = {
      resourceType: 'Bundle',
      id: 145,
      meta: {
        lastUpdated: '2009-10-10T12:00:00-05:00'
      },
      type: 'searchset',
      total: 1,
      link: [
        {
          relation: 'self',
          url: "http://www.example.com/Provenance?target=Patient/#{@patient_id}"
        }
      ],
      entry: [
        {
          fullUrl: provenance_url,
          resource: @provenance_resource
        }
      ]
    }

    @instance = Inferno::Models::TestingInstance.new(
      url: 'http://www.example.com',
      client_name: 'Inferno',
      base_url: 'http://localhost:4567',
      client_endpoint_key: Inferno::SecureRandomBase62.generate(32),
      client_id: SecureRandom.uuid,
      selected_module: 'onc_r4',
      oauth_authorize_endpoint: 'http://oauth_reg.example.com/authorize',
      oauth_token_endpoint: 'http://oauth_reg.example.com/token',
      scopes: 'launch openid patient/*.* profile',
      token: 99_897_979
    )

    @instance.save!

    @instance.resource_references << Inferno::Models::ResourceReference.new(
      resource_type: 'Patient',
      resource_id: @patient_id
    )

    @instance.supported_resources << Inferno::Models::SupportedResource.create(
      resource_type: 'Provenance',
      testing_instance_id: @instance.id,
      supported: true,
      read_supported: true
    )

    client = FHIR::Client.new(@instance.url)
    client.use_r4
    client.default_json
    @sequence = Inferno::Sequence::R4ProvenanceSequence.new(@instance, client, true)
  end

  def stub_bundle_resources(bundle)
    bundle[:entry].each do |resource|
      stub_request(:get, resource[:fullUrl])
        .with(headers: { 'Authorization' => "Bearer #{@instance.token}" })
        .to_return(
          status: 200,
          body: resource[:resource].to_json,
          headers: { content_type: 'application/json+fhir; charset=UTF-8' }
        )
    end
  end

  def full_sequence_stubs
    WebMock.reset!
    # Return 401 if no Authorization Header
    stub_request(:get, @provenance_bundle.dig(:link, 0, :url))
      .to_return(status: 401)

    # Getting Bundle, must have Authorization Header
    stub_request(:get, @provenance_bundle.dig(:link, 0, :url))
      .with(headers: { 'Authorization' => "Bearer #{@instance.token}" })
      .to_return(
        status: 200,
        body: @provenance_bundle.to_json,
        headers: { content_type: 'application/json+fhir; charset=UTF-8' }
      )

    stub_bundle_resources @provenance_bundle
  end

  def test_all_pass
    full_sequence_stubs

    sequence_result = @sequence.start

    failures = sequence_result.failures
    assert failures.empty?, "All tests should pass. First error: #{failures&.first&.message}"
    assert sequence_result.pass?, 'The sequence should be marked as pass.'
  end
end
