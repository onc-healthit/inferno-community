# frozen_string_literal: true

require_relative '../test_helper'

class SequenceBaseTest < MiniTest::Test
  def setup
    allergy_intolerance_bundle = FHIR.from_contents(load_fixture(:us_core_r4_allergy_intolerance))
    @allergy_intolerance_resource = allergy_intolerance_bundle.entry.first.resource
    @instance = Inferno::TestingInstance.new(
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

  describe '#validate_reply_entries' do
    before do
      @instance = Inferno::TestingInstance.create!
      client = FHIR::Client.new('')
      @sequence = Inferno::Sequence::USCore311AllergyintoleranceSequence.new(@instance, client, true)
      allergy_intolerance_bundle = FHIR.from_contents(load_fixture(:us_core_r4_allergy_intolerance))
      @allergy_intolerance_resource = allergy_intolerance_bundle.entry.first.resource
    end

    it 'passes if results match search params' do
      search_params = {
        'patient': '1234',
        'clinical-status': 'active'
      }
      search_params.each do |key, value|
        @sequence.validate_resource_item(@allergy_intolerance_resource, key.to_s, value)
      end
    end

    it 'fails when results do not match search params' do
      search_params = {
        'patient': '1234',
        'clinical-status': 'inactive'
      }
      error = assert_raises(Inferno::AssertionException) do
        search_params.each do |key, value|
          @sequence.validate_resource_item(@allergy_intolerance_resource, key.to_s, value)
        end
      end
      expected_error_msg = "clinical-status in AllergyIntolerance/SMART-AllergyIntolerance-28 (#{@sequence.resolve_path(@allergy_intolerance_resource, 'clinicalStatus')})"\
        ' does not match clinical-status requested (inactive)'
      assert error.message == expected_error_msg, "expected: #{expected_error_msg}, actual: #{error.message}"
    end

    it 'passes when the correct system for clinical-status is searched' do
      search_params = {
        'patient': '1234',
        'clinical-status': 'http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical|active'
      }
      search_params.each do |key, value|
        @sequence.validate_resource_item(@allergy_intolerance_resource, key.to_s, value)
      end
    end

    it 'fails when the incorrect system is searched' do
      search_params = {
        'patient': '1234',
        'clinical-status': 'http://terminology.hl7.org|active'
      }
      assert_raises(Inferno::AssertionException) do
        search_params.each do |key, value|
          @sequence.validate_resource_item(@allergy_intolerance_resource, key.to_s, value)
        end
      end
    end
  end

  describe '#date_comparator_value' do
    before do
      @instance = Inferno::TestingInstance.create!(selected_module: 'uscore_v3.0.0')
      client = FHIR::Client.new('')
      @sequence = Inferno::Sequence::SequenceBase.new(@instance, client, true)
    end

    it 'returns searches for periods' do
      period = FHIR::Period.new('start' => '2020-07-01T12:12:12+00:00')
      assert @sequence.date_comparator_value('gt', period) == 'gt2020-06-30T12:12:12+00:00'

      period = FHIR::Period.new('end' => '2020-07-01T12:12:12+00:00')
      assert @sequence.date_comparator_value('ge', period) == 'ge2020-06-30T12:12:12+00:00'

      period = FHIR::Period.new('start' => '2020-07-03')
      assert @sequence.date_comparator_value('le', period) == 'le2020-07-04T00:00:00+00:00'

      period = FHIR::Period.new('start' => '2020-07')
      assert @sequence.date_comparator_value('lt', period) == 'lt2020-07-02T00:00:00+00:00'
    end

    it 'returns searches for datetimes' do
      assert @sequence.date_comparator_value('le', '2020') == 'le2020-01-02T00:00:00+00:00'
      assert @sequence.date_comparator_value('lt', '2020-04') == 'lt2020-04-02T00:00:00+00:00'
      assert @sequence.date_comparator_value('gt', '2020-04-01') == 'gt2020-03-31T00:00:00+00:00'
      assert @sequence.date_comparator_value('ge', '2020-04-01T00:00:00+00:00') == 'ge2020-03-31T00:00:00+00:00'
    end
  end

  describe '#save_delayed_sequence_references' do
    before do
      @instance = Inferno::TestingInstance.create!(selected_module: 'uscore_v3.0.0')
      client = FHIR::Client.new('')
      @sequence = Inferno::Sequence::SequenceBase.new(@instance, client, true)
      @diagnostic_report_resource = FHIR.from_contents(load_fixture(:us_core_r4_diagnostic_report_note))
      @delayed_references = Inferno::USCore311ProfileDefinitions::USCore311DiagnosticreportNoteSequenceDefinitions::DELAYED_REFERENCES
    end

    it 'saves reference to delayed US core resources' do
      reference = FHIR::Reference.new
      reference.reference = 'Practitioner/1234'
      @diagnostic_report_resource.performer = reference
      @sequence.save_delayed_sequence_references(Array.wrap(@diagnostic_report_resource), @delayed_references)
      assert @instance.resource_references.any? { |ref| ref.resource_type == 'Practitioner' }, 'Practitioner references should be saved in DiagnosticReport.perfomer'

      reference.reference = 'Organization/1234'
      @diagnostic_report_resource.performer = reference
      @sequence.save_delayed_sequence_references(Array.wrap(@diagnostic_report_resource), @delayed_references)
      assert @instance.resource_references.any? { |ref| ref.resource_type == 'Organization' }, 'Organization references should be saved in DiagnosticReport.perfomer'
    end

    it 'does not save delayed reference when not us core resource' do
      reference = FHIR::Reference.new
      reference.reference = 'Location/1234'
      @diagnostic_report_resource.performer = reference
      @sequence.save_delayed_sequence_references(Array.wrap(@diagnostic_report_resource), @delayed_references)
      assert @instance.resource_references.none? { |ref| ref.resource_type == 'Location' }, 'Location references should be saved in DiagnosticReport.perfomer'
    end
  end

  describe '#get_value_for_search_param' do
    before do
      instance = Inferno::TestingInstance.create!(selected_module: 'uscore_v3.0.0')
      client = FHIR::Client.new('')
      @sequence = Inferno::Sequence::SequenceBase.new(instance, client, true)
    end

    it 'returns value from period' do
      [
        {
          element: FHIR::Period.new('start' => '2020'),
          expected: 'gt2019-12-31T00:00:00+00:00'
        },
        {
          element: FHIR::Period.new('start' => '2020', 'end' => '2020'),
          expected: 'gt2019-12-31T00:00:00+00:00'
        },
        {
          element: FHIR::Period.new('end' => '2020'),
          expected: 'lt2021-01-01T23:59:59+00:00'
        },
        {
          element: FHIR::Period.new('start' => '2020-01'),
          expected: 'gt2019-12-31T00:00:00+00:00'
        },
        {
          element: FHIR::Period.new('end' => '2020-01'),
          expected: 'lt2020-02-01T23:59:59+00:00'
        },
        {
          element: FHIR::Period.new('start' => '2020-01-01'),
          expected: 'gt2019-12-31T00:00:00+00:00'
        },
        {
          element: FHIR::Period.new('end' => '2020-01-01'),
          expected: 'lt2020-01-02T23:59:59+00:00'
        },
        {
          element: FHIR::Period.new('start' => '2015-02-07T13:28:17-05:00'),
          expected: 'gt2015-02-06T13:28:17-05:00'
        },
        {
          element: FHIR::Period.new('end' => '2015-02-07T13:28:17-05:00'),
          expected: 'lt2015-02-08T13:28:17-05:00'
        }
      ].each do |expectation|
        actual_value = @sequence.get_value_for_search_param(expectation[:element])
        assert actual_value == expectation[:expected], "Expected: #{expectation[:expected]}, Saw: #{actual_value}"
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
        assert @sequence.get_value_for_search_param(element) == value
      end
    end
  end

  describe '#fetch_all_bundled_resources' do
    before do
      @bundle1 = FHIR.from_contents(load_fixture(:bundle_1))
      @bundle2 = load_fixture(:bundle_2)

      instance = Inferno::TestingInstance.create!(selected_module: 'uscore_v3.0.0')
      client = FHIR::Client.new('')
      @bundle1.client = client
      @sequence = Inferno::Sequence::SequenceBase.new(instance, client, true)
    end

    it 'returns resources from all bundles' do
      stub_request(:get, @bundle1.link.first.url)
        .to_return(body: @bundle2)

      all_resources = @sequence.fetch_all_bundled_resources(OpenStruct.new(resource: @bundle1))
      assert all_resources.map(&:id) == ['1', '2']
    end

    it 'fails on 404' do
      stub_request(:get, @bundle1.link.first.url)
        .to_return(body: '', status: 404)

      assert_raises Inferno::AssertionException do
        @sequence.fetch_all_bundled_resources(OpenStruct.new(resource: @bundle1))
      end
    end

    it 'returns resources when no next page' do
      all_resources = @sequence.fetch_all_bundled_resources(
        OpenStruct.new(resource: FHIR.from_contents(@bundle2))
      )
      assert all_resources.map(&:id) == ['2']
    end
  end

  describe '.test' do
    it 'raises an error if two tests have duplicate keys' do
      assert_raises(Inferno::InvalidKeyException) do
        class InvalidKeySequence < Inferno::Sequence::SequenceBase
          2.times do |index|
            test :a do
              metadata do
                id "0#{index + 1}"
                name 'a'
                description 'a'
                link 'http://example.com'
              end
            end
          end
        end
      end
    end
  end

  class OptionalTestSequence < Inferno::Sequence::SequenceBase
    2.times do |index|
      test :"test #{index}" do
        metadata do
          id "0#{index + 1}"
          name 'a'
          description 'a'
          link 'http://example.com'
          optional if index.odd?
        end
      end
    end
  end

  describe '.tests' do
    before do
      @sequence_class = OptionalTestSequence
    end

    it 'returns all tests if no arguments are given' do
      assert_equal 2, @sequence_class.tests.length
    end

    it 'returns all tests if module.hide_optional is false' do
      inferno_module = OpenStruct.new(hide_optional: false)

      assert_equal 2, @sequence_class.tests(inferno_module).length
    end

    it 'returns only required if module.hide_optional is truth' do
      inferno_module = OpenStruct.new(hide_optional: true)

      assert_equal 1, @sequence_class.tests(inferno_module).length
      @sequence_class.tests(inferno_module).each { |test| assert_equal true, test.required? }
    end
  end

  describe '.test_count' do
    before do
      @sequence_class = OptionalTestSequence
    end

    it 'includes all tests if no arguments are given' do
      assert_equal 2, @sequence_class.test_count
    end

    it 'includes all tests if module.hide_optional is false' do
      inferno_module = OpenStruct.new(hide_optional: false)

      assert_equal 2, @sequence_class.test_count(inferno_module)
    end

    it 'returns only required if module.hide_optional is truth' do
      inferno_module = OpenStruct.new(hide_optional: true)

      assert_equal 1, @sequence_class.test_count(inferno_module)
    end
  end

  describe '#tests' do
    before do
      @instance = Inferno::TestingInstance.create!
      client = FHIR::Client.new('')
      @sequence = OptionalTestSequence.new(@instance, client)
    end

    it 'uses @instance.module if no argument is supplied' do
      module_without_optional = OpenStruct.new(hide_optional: true)
      module_with_optional = OpenStruct.new(hide_optional: false)

      @instance.instance_variable_set(:@module, module_without_optional)
      assert_equal 1, @sequence.tests.length

      @instance.instance_variable_set(:@module, module_with_optional)
      assert_equal 2, @sequence.tests.length
    end
  end

  describe '#test_count' do
    before do
      @instance = Inferno::TestingInstance.create!
      client = FHIR::Client.new('')
      @sequence = OptionalTestSequence.new(@instance, client)
    end

    it 'uses @instance.module if no argument is supplied' do
      module_without_optional = OpenStruct.new(hide_optional: true)
      module_with_optional = OpenStruct.new(hide_optional: false)

      @instance.instance_variable_set(:@module, module_without_optional)
      assert_equal 1, @sequence.test_count

      @instance.instance_variable_set(:@module, module_with_optional)
      assert_equal 2, @sequence.test_count
    end
  end

  describe '#find_slice_by_values' do
    before do
      @instance = Inferno::TestingInstance.create!
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
      assert @sequence.find_slice_by_values(element_as_obj, values).blank?
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
      assert @sequence.find_slice_by_values(element_as_obj, values).present?
    end
  end
end
