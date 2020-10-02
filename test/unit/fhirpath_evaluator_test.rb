# frozen_string_literal: true

require 'json'
require 'fhir_client'
require_relative '../test_helper'

describe Inferno::FHIRPathEvaluator do
  before do
    @fhirpath_url = 'http://example.com:8080'
    @evaluator = Inferno::FHIRPathEvaluator.new(@fhirpath_url)
  end

  describe 'Evaluating a FHIRPath against elements' do
    it 'Should return an empty collection if given an empty array' do
      assert_equal [], @evaluator.evaluate([], 'Patient')
    end

    it 'Should accept a single element and return fhir_models' do
      patient = FHIR::Patient.new(id: 'foo')
      response = "[{ \"type\": \"Patient\", \"element\": #{patient.to_json} }]"

      stub_request(:post, "#{@fhirpath_url}/evaluate")
        .with(query: hash_including(path: 'Patient'), body: patient.to_json)
        .to_return(body: response)

      assert_equal [patient], @evaluator.evaluate(patient, 'Patient')
    end

    it 'Should return a collection of ids' do
      patients = (1..3).map { |id| FHIR::Patient.new(id: id.to_s) }
      responses = patients.map { |p| { body: [{ type: 'string', element: p.id }].to_json } }

      stub_request(:post, "#{@fhirpath_url}/evaluate")
        .with(query: hash_including(path: 'Patient.id'))
        .to_return(*responses)

      assert_equal ['1', '2', '3'], @evaluator.evaluate(patients, 'Patient.id')
    end

    it 'Should successfully return Element fhir_models' do
      patients = (1..3).map { |name| FHIR::Patient.new(name: [{ given: [name.to_s] }]) }
      names = patients.map { |p| p.name[0] }
      responses = names.map do |name|
        { body: "[{ \"type\": \"HumanName\", \"element\": #{name.to_json} }]" }
      end

      stub_request(:post, "#{@fhirpath_url}/evaluate")
        .with(query: hash_including(path: 'Patient.name'))
        .to_return(*responses)

      assert(names.all? { |name| name.is_a?(FHIR::HumanName) })
      assert_equal names, @evaluator.evaluate(patients, 'Patient.name')
    end

    it 'Should successfully return BackboneElement fhir_models' do
      patient = FHIR::Patient.new(contact: [{ name: { given: ['1'] } }])
      contact = patient.contact[0]
      response = "[{ \"type\": \"Patient.contact\", \"element\": #{contact.to_json} }]"

      stub_request(:post, "#{@fhirpath_url}/evaluate")
        .with(query: hash_including(path: 'Patient.contact'))
        .to_return(body: response)

      assert_equal [contact], @evaluator.evaluate(patient, 'Patient.contact')
    end

    it 'Should successfully post Element fhir_models' do
      name = FHIR::HumanName.new(given: ['Foo'])
      response = '[{ "type": "string", "element": "Foo" }]'

      stub_request(:post, "#{@fhirpath_url}/evaluate")
        .with(query: hash_including(path: 'HumanName.given', type: 'HumanName'), body: name.to_json)
        .to_return(body: response)

      assert_equal ['Foo'], @evaluator.evaluate(name, 'HumanName.given')
    end

    it 'Should successfully post BackboneElement fhir_models' do
      contact = FHIR::Patient::Contact.new(name: { given: ['1'] }, gender: 'male')
      response = '[{ "type": "code", "element": "male"}]'

      stub_request(:post, "#{@fhirpath_url}/evaluate")
        .with(query: hash_including(path: 'gender', type: 'Patient.contact'), body: contact.to_json)
        .to_return(body: response)

      assert_equal ['male'], @evaluator.evaluate(contact, 'gender')
    end
  end
end
