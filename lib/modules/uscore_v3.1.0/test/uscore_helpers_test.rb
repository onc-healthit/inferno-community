require_relative '../../../../test/test_helper'
require_relative '../uscore_helpers'

include Inferno::USCoreHelpers
describe Inferno::USCoreHelpers do
  def test_save_delayed_resource_references
    allergy_intolerance_resource = FHIR.from_contents(load_fixture(:us_core_allergyintolerance))

    delayed_resources = ['Location', 'Medication', 'Organization', 'Practitioner', 'PractitionerRole']
    some_non_delayed_resources = ['AllergyIntolerance', 'CarePlan', 'Careteam', 'Condition', 'Device', 'Observation', 'Encounter', 'Goal']

    delayed_resources.each do |res|
      set_resource_reference(allergy_intolerance_resource, res)
      @sequence.save_delayed_sequence_references(Array.wrap(allergy_intolerance_resource))
      assert @instance.resource_references.any? { |ref| ref.resource_type == res }, "#{res} reference should be saved"
    end
    some_non_delayed_resources.each do |res|
      set_resource_reference(allergy_intolerance_resource, res)
      @sequence.save_delayed_sequence_references(Array.wrap(allergy_intolerance_resource))
      assert @instance.resource_references.none? { |ref| ref.resource_type == res }, "#{res} reference should not be saved"
    end
  end

  def set_resource_reference(resource, type)
    new_reference = FHIR::Reference.new
    new_reference.reference = "#{type}/1234"
    resource.recorder = new_reference
  end

  describe '#get_value_for_search_param' do
    before do
      instance = Inferno::Models::TestingInstance.create(selected_module: 'uscore_v3.0.0')
      client = FHIR::Client.new('')
      @sequence = Inferno::Sequence::SequenceBase.new(instance, client, true)
    end

    it 'returns value from period' do
      { start: 'now', end: 'later' }.each do |key, value|
        element = FHIR::Period.new(key => value)
        expected_value = if key == :start
                           'gt' + value
                         else
                           'lt' + value
                         end
        assert get_value_for_search_param(element) == expected_value
      end
    end

    it 'returns value from address' do
      {
        state: 'mass',
        text: 'mitre',
        postalCode: '12345',
        city: 'boston',
        country: 'usa'
      }.each do |key, value|
        element = FHIR::Address.new(key => value)
        assert get_value_for_search_param(element) == value
      end
    end
  end

  describe '#find_slice_by_values' do
    before do
      @instance = Inferno::Models::TestingInstance.create
      client = FHIR::Client.new('')
      @sequence = Inferno::Sequence::SequenceBase.new(@instance, client, true)
    end

    it 'fails to find anything when values match on different elements in array' do
      values = [
        {
          path: ['coding', 'code'],
          value: 'correct-code'
        },
        {
          path: ['coding', 'system'],
          value: 'correct-system'
        }
      ]
      element = {
        coding: [
          { code: 'correct-code', system: 'wrong-system' },
          { code: 'wrong-code', system: 'correct-system' }
        ]
      }
      element_as_obj = JSON.parse(element.to_json, object_class: OpenStruct)
      assert find_slice_by_values(element_as_obj, values).blank?
    end

    it 'succeeds to find slice' do
      values = [
        {
          path: ['coding', 'code'],
          value: 'correct-code'
        },
        {
          path: ['coding', 'system'],
          value: 'correct-system'
        }
      ]
      element = {
        coding: [
          { code: 'correct-code', system: 'correct-system' },
          { code: 'wrong-code', system: 'wrong-system' }
        ]
      }
      element_as_obj = JSON.parse(element.to_json, object_class: OpenStruct)
      assert find_slice_by_values(element_as_obj, values).present?
    end
  end
end
