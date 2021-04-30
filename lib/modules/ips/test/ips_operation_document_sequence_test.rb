# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::IpsDocumentOperationSequence do
  before do
    @sequence_class = Inferno::Sequence::IpsDocumentOperationSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @instance = Inferno::TestingInstance.create(url: @base_url, token: @token, selected_module: 'ips')
    @client = FHIR::Client.for_testing_instance(@instance)
    @composition_resource = FHIR.from_contents(load_fixture(:composition))
    @document_response = FHIR.from_contents(load_fixture(:document_response))
    @instance.composition_id = @composition_resource.id
  end

  describe 'Document operation on composition' do
    before do
      @test = @sequence_class[:document_operator]
      @sequence = @sequence_class.new(@instance, @client)
      stub_request(:get, "#{@base_url}/Composition/#{@composition_resource.id}")
      .to_return(status: 200,
        body: @composition_resource.to_json)
    end

    it 'fails if search fails' do
      stub_request(:get, "#{@base_url}/Composition/#{@composition_resource.id}/$document?persist=true")
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a referenced resource is missing' do
      @document_response.entry.pop
      stub_request(:get, "#{@base_url}/Composition/#{@composition_resource.id}/$document?persist=true")
        .to_return(status: 200, body: @document_response.to_json)

      assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    end

    it 'succeeds if all referenced resources are returned' do
      stub_request(:get, "#{@base_url}/Composition/#{@composition_resource.id}/$document?persist=true")
        .to_return(status: 200, body: @document_response.to_json)

      @sequence.run_test(@test)
    end
  end
end
