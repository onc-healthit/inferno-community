# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310DocumentreferenceSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310DocumentreferenceSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(url: @base_url, token: @token, selected_module: 'uscore_v3.1.0')
    @client = FHIR::Client.for_testing_instance(@instance)
    @patient_id = 'example'
    @instance.patient_id = @patient_id
    set_resource_support(@instance, 'DocumentReference')
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'resource validation test' do
    before do
      @document_reference = FHIR::DocumentReference.new(load_json_fixture(:us_core_documentreference))
      @test = @sequence_class[:validate_resources]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:'@resources_found', true)

      Inferno::Models::ResourceReference.create(
        resource_type: 'DocumentReference',
        resource_id: @document_reference.id,
        testing_instance: @instance
      )
    end

    it 'fails if a resource does not contain a code for a CodeableConcept with a required binding' do
      ['type'].each do |path|
        @sequence.resolve_path(@document_reference, path).each do |concept|
          concept&.coding&.each do |coding|
            coding&.code = nil
            coding&.system = nil
          end
          concept&.text = 'abc'
        end
      end

      stub_request(:get, "#{@base_url}/DocumentReference/#{@document_reference.id}")
        .with(headers: @auth_header)
        .to_return(status: 200, body: @document_reference.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      ['type'].each do |path|
        assert_match(%r{DocumentReference/#{@document_reference.id}: The CodeableConcept at '#{path}' is bound to a required ValueSet but does not contain any codes\.}, exception.message)
      end
    end
  end
end
