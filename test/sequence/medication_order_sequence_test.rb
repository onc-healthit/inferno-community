# frozen_string_literal: true

require_relative '../test_helper'

# Tests for the Medication Order Sequence
# It makes sure all the sequences pass and ensures no duplicate resource references occur from multiple runs
class MedicationOrderSequenceTest < MiniTest::Test
  def setup
    @patient_id = 1234
    @medication_order_bundle = {
      resourceType: 'Bundle',
      id: 145,
      meta: {
        lastUpdated: '2009-10-10T12:00:00-05:00'
      },
      type: 'searchset',
      total: 2,
      link: [
        {
          relation: 'self',
          url: "http://www.example.com/MedicationOrder?patient=#{@patient_id}"
        }
      ],
      entry: []
    }

    @history_bundle = @medication_order_bundle.deep_dup
    @history_bundle[:type] = 'history'
    @history_bundle[:total] = 1

    @medication_order13 = load_json_fixture(:medication_13)
    @medication_order14 = load_json_fixture(:medication_14)

    @medication_order_bundle[:entry] << {
      resource: @medication_order13,
      fullUrl: 'http://www.example.com/MedicationOrder/13'
    }
    @medication_order_bundle[:entry] << {
      resource: @medication_order14,
      fullUrl:  'http://www.example.com/MedicationOrder/14'
    }

    @instance = Inferno::Models::TestingInstance.new(url: 'http://www.example.com',
                                                     client_name: 'Inferno',
                                                     base_url: 'http://localhost:4567',
                                                     client_endpoint_key: Inferno::SecureRandomBase62.generate(32),
                                                     client_id: SecureRandom.uuid,
                                                     oauth_authorize_endpoint: 'http://oauth_reg.example.com/authorize',
                                                     oauth_token_endpoint: 'http://oauth_reg.example.com/token',
                                                     scopes: 'launch openid patient/*.* profile',
                                                     token: 99_897_979)

    @instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.

    # Assume we already have a patient
    @instance.resource_references << Inferno::Models::ResourceReference.new(
      resource_type: 'Patient',
      resource_id: @patient_id
    )

    @instance.supported_resources << Inferno::Models::SupportedResource.create(
      resource_type: 'MedicationOrder',
      testing_instance_id: @instance.id,
      supported: true,
      read_supported: true,
      vread_supported: true,
      search_supported: true,
      history_supported: true
    )

    client = FHIR::Client.new(@instance.url)
    client.use_dstu2
    client.default_json
    @sequence = Inferno::Sequence::ArgonautMedicationOrderSequence.new(@instance, client, true)
  end

  def stub_get_med(med_res)
    # Getting Medication, must have Authorization Header
    med_res[:entry].each do |resource|
      stub_request(:get, resource[:fullUrl])
        .with(headers: {
                'Authorization' => "Bearer #{@instance.token}"
              })
        .to_return(status: 200,
                   body: resource[:resource].to_json,
                   headers: { content_type: 'application/json+fhir; charset=UTF-8' })
    end
  end

  def stub_history(med_res)
    # Getting Medication Resource History, must have Authorization Header
    med_res[:entry].each do |resource|
      @history_bundle[:entry] = [{
        fullUrl: resource[:fullUrl],
        resource: resource[:resource]
      }]

      stub_request(:get, resource[:fullUrl] + '/_history')
        .with(headers: {
                'Authorization' => "Bearer #{@instance.token}"
              })
        .to_return(status: 200,
                   body: @history_bundle.to_json,
                   headers: { content_type: 'application/json+fhir; charset=UTF-8' })
    end
  end

  def stub_vread(med_res)
    # Getting Medication Resource History, must have Authorization Header
    med_res[:entry].each do |resource|
      stub_request(:get, resource[:fullUrl] + '/_history/1')
        .with(headers: {
                'Authorization' => "Bearer #{@instance.token}"
              })
        .to_return(status: 200,
                   body: resource[:resource].to_json,
                   headers: { content_type: 'application/json+fhir; charset=UTF-8' })
    end
  end

  def full_sequence_stubs
    WebMock.reset!
    # Return 401 if no Authorization Header
    stub_request(:get, @medication_order_bundle.dig(:link, 0, :url)).to_return(status: 401)

    # Getting Bundle, must have Authorization Header
    stub_request(:get, @medication_order_bundle.dig(:link, 0, :url))
      .with(headers: {
              'Authorization' => "Bearer #{@instance.token}"
            })
      .to_return(status: 200,
                 body: @medication_order_bundle.to_json,
                 headers: { content_type: 'application/json+fhir; charset=UTF-8' })

    stub_get_med @medication_order_bundle
    stub_history @medication_order_bundle
    stub_vread @medication_order_bundle
  end

  def test_all_pass
    full_sequence_stubs

    sequence_result = @sequence.start

    failures = sequence_result.test_results.select { |r| r.result != 'pass' && r.result != 'skip' }
    assert failures.empty?, "All tests should pass.  First error: #{!failures.empty? && failures.first.message}"
    assert sequence_result.result == 'pass', 'The sequence should be marked as pass.'
  end

  def test_no_duplicate_orders
    full_sequence_stubs

    sequence_result = @sequence.start
    sequence_result.save!

    puts 'Running second sequence...'

    # When sequences are rerun with the Sinatra Interface new sequences are created
    client = FHIR::Client.new(@instance.url)
    client.use_dstu2
    client.default_json
    secondInstance = Inferno::Models::TestingInstance.get(@instance[:id])
    secondInstance.patient_id= @patient_id
    second_sequence = Inferno::Sequence::ArgonautMedicationOrderSequence.new(secondInstance, client, true)
    second_sequence.start
    assert secondInstance.resource_references.length == 3, 'There should only be two reference resources...' \
                                                      "but #{secondInstance.resource_references.length} were found\n" \
                                                      "They are: #{secondInstance.resource_references.map do |reference|
                                                                     reference[:resource_type] + reference[:resource_id]
                                                                   end.join(', ')} \n" \
                                                      'Check for duplicates.'
  end
end
