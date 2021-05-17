# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::IpsSummaryOperationSequence do
  before do
    @sequence_class = Inferno::Sequence::IpsSummaryOperationSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @instance = Inferno::TestingInstance.create(url: @base_url, token: @token, selected_module: 'ips')
    @client = FHIR::Client.for_testing_instance(@instance)
    @bundle = FHIR.from_contents(load_fixture('bundle-minimal'))
    @instance.patient_id = '2b90dd2b-2dab-4c75-9bb9-a355e07401e8'
  end

  describe 'Server support $summary operation' do
    before do
      @test = @sequence_class[:support_summay]
      @sequence = @sequence_class.new(@instance, @client)
      @request_url = "#{@base_url}/metadata"
      @headers = { 'Accept' => 'application/fhir+json' }
      @capabilitystatement = FHIR.from_contents(load_fixture('capabilitystatement'))
    end

    it 'fails if CapabilityStatement does not support Patient resourcce' do
      @capabilitystatement.rest.first.resource.delete_if { |r| r.type == 'Patient' }
      stub_request(:get, @request_url)
        .with(headers: @headers)
        .to_return(status: 200, body: @capabilitystatement.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal('Server CapabilityStatement did not declare support for summary operation in Patient resource.', exception.message)
    end

    it 'fails if CapabilityStatement does not support $summary operation' do
      patient = @capabilitystatement.rest.first.resource.select { |r| r.type == 'Patient' }
      patient.first.operation.delete_if { |op| op.name == 'summary' }
      stub_request(:get, @request_url)
        .with(headers: @headers)
        .to_return(status: 200, body: @capabilitystatement.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal('Server CapabilityStatement did not declare support for summary operation in Patient resource.', exception.message)
    end

    it 'passes with valid CapabilityStatement' do
      stub_request(:get, @request_url)
        .with(headers: @headers)
        .to_return(status: 200, body: @capabilitystatement.to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'Summary operation returns valiad IPS Bundle resource' do
    before do
      @test = @sequence_class[:run_operation]
      @sequence = @sequence_class.new(@instance, @client)
      @request_url = "#{@base_url}/Patient/#{@instance.patient_id}/$summary"
      @headers = { 'Accept' => 'application/fhir+json' }
    end

    it 'fails if operation fails' do
      stub_request(:post, @request_url)
        .with(headers: @headers)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal('Bad response code: expected 200, 201, but found 401. ', exception.message)
    end

    it 'fails if a response is not a Bundle' do
      stub_request(:post, @request_url)
        .with(headers: @headers)
        .to_return(status: 200, body: FHIR::Composition.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
      assert_equal('Expected FHIR Bundle but found: Composition', exception.message)
    end

    it 'fails if Bundle does not have Composition' do
      @bundle.entry.delete_if { |entry| entry.resource.class == FHIR::Composition }
      stub_request(:post, @request_url)
        .with(headers: @headers)
        .to_return(status: 200, body: @bundle.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
      assert_match(/Bundle.entry failed cardinality test/, exception.message)
    end

    it 'fails if Bundle does not have MedicationStatement' do
      @bundle.entry.delete_if { |entry| entry.resource.class == FHIR::Composition }
      stub_request(:post, @request_url)
        .with(headers: @headers)
        .to_return(status: 200, body: @bundle.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
      assert_match(/Bundle.entry failed cardinality test/, exception.message)
    end

    it 'fails if Bundle does not have AllergyIntolerance' do
      @bundle.entry.delete_if { |entry| entry.resource.class == FHIR::AllergyIntolerance }
      stub_request(:post, @request_url)
        .with(headers: @headers)
        .to_return(status: 200, body: @bundle.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
      assert_match(/Bundle.entry failed cardinality test/, exception.message)
    end

    it 'fails if Bundle does not have Condition' do
      @bundle.entry.delete_if { |entry| entry.resource.class == FHIR::Condition }
      stub_request(:post, @request_url)
        .with(headers: @headers)
        .to_return(status: 200, body: @bundle.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
      assert_match(/Bundle.entry failed cardinality test/, exception.message)
    end

    # TODO: Why the example could not pass validator?
    # it 'passes with valid Bundle resource' do
    #   stub_request(:post, @request_url)
    #     .with(headers: @headers)
    #     .to_return(status: 200, body: @bundle.to_json)

    #   @sequence.run_test(@test)
    # end
  end

  describe 'Summary operation returns valiad IPS Composition in Bundle resource' do
    before do
      @test = @sequence_class[:validate_composition]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'fails if Bundle is empty' do
      @bundle.entry = []
      @sequence.instance_variable_set(:'@bundle', @bundle)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal('Bundle has empty entry', exception.message)
    end

    it 'fails if Bundle does not have Composition' do
      @bundle.entry.delete_if { |entry| entry.resource.class == FHIR::Composition }
      @sequence.instance_variable_set(:'@bundle', @bundle)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
      assert_equal('The first entry in Bundle is not Composition', exception.message)
    end

    it 'fails if Bundle does not have Composition as first entry' do
      temp = @bundle.entry[1]
      @bundle.entry[1] = @bundle.entry[0]
      @bundle.entry[0] = temp
      @sequence.instance_variable_set(:'@bundle', @bundle)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
      assert_equal('The first entry in Bundle is not Composition', exception.message)
    end

    # it 'fails if Bundle does not have Composition' do
    #   @bundle.entry.delete_if{ |entry| entry.resource.class == FHIR::Composition }
    #   stub_request(:post, @request_url)
    #     .with(headers: @headers)
    #     .to_return(status: 200, body: @bundle.to_json)

    #   exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    #   assert_match(/Bundle.entry failed cardinality test/, exception.message)
    # end

    # it 'fails if Bundle does not have MedicationStatement' do
    #   @bundle.entry.delete_if{ |entry| entry.resource.class == FHIR::Composition }
    #   stub_request(:post, @request_url)
    #     .with(headers: @headers)
    #     .to_return(status: 200, body: @bundle.to_json)

    #   exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    #   assert_match(/Bundle.entry failed cardinality test/, exception.message)
    # end

    # it 'fails if Bundle does not have AllergyIntolerance' do
    #   @bundle.entry.delete_if{ |entry| entry.resource.class == FHIR::AllergyIntolerance }
    #   stub_request(:post, @request_url)
    #     .with(headers: @headers)
    #     .to_return(status: 200, body: @bundle.to_json)

    #   exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    #   assert_match(/Bundle.entry failed cardinality test/, exception.message)
    # end

    # it 'fails if Bundle does not have Condition' do
    #   @bundle.entry.delete_if{ |entry| entry.resource.class == FHIR::Condition }
    #   stub_request(:post, @request_url)
    #     .with(headers: @headers)
    #     .to_return(status: 200, body: @bundle.to_json)

    #   exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    #   assert_match(/Bundle.entry failed cardinality test/, exception.message)
    # end

    # it 'passes with valid IPS Composition resource' do
    #   @sequence.instance_variable_set(:'@bundle', @bundle)

    #   @sequence.run_test(@test)
    # end
  end

  describe 'Summary operation returns valiad IPS MedicationStatement in Bundle resource' do
    before do
      @test = @sequence_class[:validate_medication_statement]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'fails if Bundle does not have MedicationStatement' do
      @bundle.entry.delete_if { |entry| entry.resource.class == FHIR::MedicationStatement }
      @sequence.instance_variable_set(:'@bundle', @bundle)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
      assert_equal('Bundle does NOT have any MedicationStatement entries', exception.message)
    end

    # it 'fails if Bundle does not have Composition' do
    #   @bundle.entry.delete_if{ |entry| entry.resource.class == FHIR::Composition }
    #   stub_request(:post, @request_url)
    #     .with(headers: @headers)
    #     .to_return(status: 200, body: @bundle.to_json)

    #   exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    #   assert_match(/Bundle.entry failed cardinality test/, exception.message)
    # end

    # it 'fails if Bundle does not have MedicationStatement' do
    #   @bundle.entry.delete_if{ |entry| entry.resource.class == FHIR::Composition }
    #   stub_request(:post, @request_url)
    #     .with(headers: @headers)
    #     .to_return(status: 200, body: @bundle.to_json)

    #   exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    #   assert_match(/Bundle.entry failed cardinality test/, exception.message)
    # end

    # it 'fails if Bundle does not have AllergyIntolerance' do
    #   @bundle.entry.delete_if{ |entry| entry.resource.class == FHIR::AllergyIntolerance }
    #   stub_request(:post, @request_url)
    #     .with(headers: @headers)
    #     .to_return(status: 200, body: @bundle.to_json)

    #   exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    #   assert_match(/Bundle.entry failed cardinality test/, exception.message)
    # end

    # it 'fails if Bundle does not have Condition' do
    #   @bundle.entry.delete_if{ |entry| entry.resource.class == FHIR::Condition }
    #   stub_request(:post, @request_url)
    #     .with(headers: @headers)
    #     .to_return(status: 200, body: @bundle.to_json)

    #   exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    #   assert_match(/Bundle.entry failed cardinality test/, exception.message)
    # end

    it 'passes with valid IPS Composition resource' do
      @sequence.instance_variable_set(:'@bundle', @bundle)

      @sequence.run_test(@test)
    end
  end
end
