# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310AllergyintoleranceSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310AllergyintoleranceSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(url: @base_url, token: @token, selected_module: 'uscore_v3.1.0')
    @client = FHIR::Client.for_testing_instance(@instance)
    @patient_id = 'example'
    @instance.patient_id = @patient_id
    set_resource_support(@instance, 'AllergyIntolerance')
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'resource validation test' do
    before do
      @allergy_intolerance = FHIR::AllergyIntolerance.new(load_json_fixture(:us_core_allergyintolerance))
      @test = @sequence_class[:validate_resources]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:'@resources_found', true)

      Inferno::Models::ResourceReference.create(
        resource_type: 'AllergyIntolerance',
        resource_id: @allergy_intolerance.id,
        testing_instance: @instance
      )
    end

    it 'fails if a resource does not contain a code for a CodeableConcept with a required binding' do
      ['clinicalStatus', 'verificationStatus'].each do |path|
        @sequence.resolve_path(@allergy_intolerance, path).each do |concept|
          concept&.coding&.each do |coding|
            coding&.code = nil
            coding&.system = nil
          end
          concept&.text = 'abc'
        end
      end

      stub_request(:get, "#{@base_url}/AllergyIntolerance/#{@allergy_intolerance.id}")
        .with(headers: @auth_header)
        .to_return(status: 200, body: @allergy_intolerance.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      ['clinicalStatus', 'verificationStatus'].each do |path|
        assert_match(%r{AllergyIntolerance/#{@allergy_intolerance.id}: The CodeableConcept at '#{path}' is bound to a required ValueSet but does not contain any codes\.}, exception.message)
      end
    end
  end
end
