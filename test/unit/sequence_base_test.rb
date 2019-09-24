# frozen_string_literal: true

require_relative '../test_helper'

class SequenceBaseTest < MiniTest::Test
  def setup
    allergy_intolerance_bundle = FHIR.from_contents(load_fixture(:us_core_r4_allergy_intolerance))
    @allergy_intolerance_resource = allergy_intolerance_bundle.entry.first.resource
    @instance = Inferno::Models::TestingInstance.new(
      url: 'http://www.example.com',
      client_name: 'Inferno',
      base_url: 'http://localhost:4567',
      client_endpoint_key: Inferno::SecureRandomBase62.generate(32),
      client_id: SecureRandom.uuid,
      selected_module: 'us_core_r4',
      oauth_authorize_endpoint: 'http://oauth_reg.example.com/authorize',
      oauth_token_endpoint: 'http://oauth_reg.example.com/token',
      scopes: 'launch openid patient/*.* profile',
      token: 99_897_979
    )

    @instance.save!

    client = FHIR::Client.new(@instance.url)
    client.use_r4
    client.default_json
    @sequence = Inferno::Sequence::SequenceBase.new(@instance, client, true)
  end

  def test_save_delayed_resource_references
    delayed_resources = ['Location', 'Medication', 'Organization', 'Practitioner', 'PractitionerRole']
    some_non_delayed_resources = ['AllergyIntolerance', 'CarePlan', 'Careteam', 'Condition', 'Device', 'Observation', 'Encounter', 'Goal']

    delayed_resources.each do |res|
      set_resource_reference(@allergy_intolerance_resource, res)
      @sequence.save_delayed_sequence_references(@allergy_intolerance_resource)
      assert @instance.resource_references.any? { |ref| ref.resource_type == res }, "#{res} reference should be saved"
    end
    some_non_delayed_resources.each do |res|
      set_resource_reference(@allergy_intolerance_resource, res)
      @sequence.save_delayed_sequence_references(@allergy_intolerance_resource)
      assert @instance.resource_references.none? { |ref| ref.resource_type == res }, "#{res} reference should not be saved"
    end
  end

  def set_resource_reference(resource, type)
    new_reference = FHIR::Reference.new
    new_reference.reference = "#{type}/1234"
    resource.recorder = new_reference
  end
end
