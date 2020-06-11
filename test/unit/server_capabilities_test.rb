# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/app/models/server_capabilities'
require_relative '../../lib/app/models/testing_instance'

class ServerCapabilitiesTest < MiniTest::Test
  def setup
    @capability_statement = {
      rest: [
        {
          resource: [
            {
              type: 'Patient',
              interaction: [
                { code: 'read' },
                { code: 'vread' },
                { code: 'history-instance' },
                { code: 'search-type', documentation: 'DOCUMENTATION' }
              ],
              searchParam: [
                {
                  name: '_id',
                  type: 'token'
                },
                {
                  name: 'birthdate',
                  type: 'date'
                }
              ],
              searchRevInclude: [
                'Provenance:target',
                'Condition:subject'
              ],
              searchInclude: ['*']
            },
            {
              type: 'Condition',
              profile: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-condition|3.1.0',
              interaction: [
                { code: 'delete' },
                { code: 'update' },
                { code: 'search-type' }
              ],
              searchRevInclude: ['*'],
              searchInclude: [
                'Practitioner:asserter',
                'Patient:subject'
              ]
            },
            {
              type: 'Observation',
              supportedProfile: [
                'http://hl7.org/fhir/us/core/StructureDefinition/pediatric-bmi-for-age|3.1.0',
                'http://hl7.org/fhir/us/core/StructureDefinition/pediatric-weight-for-height'
              ]
            }
          ]
        }
      ]
    }

    @capabilities = Inferno::Models::ServerCapabilities.new(
      testing_instance_id: Inferno::Models::TestingInstance.create.id,
      capabilities: @capability_statement
    )

    @smart_capability_statement = {
      rest: [
        {
          security: {
            extension: [
              {
                url: 'http://fhir-registry.smarthealthit.org/StructureDefinition/capabilities',
                valueCode: 'launch-ehr'
              },
              {
                url: 'http://fhir-registry.smarthealthit.org/StructureDefinition/capabilities',
                valueCode: 'launch-standalone'
              }
            ]
          }
        }
      ]
    }

    @smart_capabilities = Inferno::Models::ServerCapabilities.new(
      testing_instance_id: Inferno::Models::TestingInstance.create.id,
      capabilities: @smart_capability_statement
    )
  end

  def test_supported_resources
    expected_resources = Set.new(['Patient', 'Condition', 'Observation'])

    assert @capabilities.supported_resources == expected_resources
  end

  def test_supported_interactions
    expected_interactions = [
      {
        resource_type: 'Patient',
        interactions: ['history-instance', 'read', 'search', 'vread'],
        operations: []
      },
      {
        resource_type: 'Condition',
        interactions: ['delete', 'search', 'update'],
        operations: []
      },
      {
        resource_type: 'Observation',
        interactions: [],
        operations: []
      }
    ]

    assert @capabilities.supported_interactions == expected_interactions
  end

  def test_operation_supported_pass
    conformance = load_json_fixture(:bulk_data_conformance)

    server_capabilities = Inferno::Models::ServerCapabilities.new(
      testing_instance_id: Inferno::Models::TestingInstance.create.id,
      capabilities: conformance.as_json
    )

    assert server_capabilities.operation_supported?('patient-export')
  end

  def test_operation_supported_fail_invalid_name
    conformance = load_json_fixture(:bulk_data_conformance)

    server_capabilities = Inferno::Models::ServerCapabilities.new(
      testing_instance_id: Inferno::Models::TestingInstance.create.id,
      capabilities: conformance.as_json
    )

    assert !server_capabilities.operation_supported?('this_is_a_test')
  end

  def test_smart_support
    assert !@capabilities.smart_support?
    assert @smart_capabilities.smart_support?
  end

  def test_smart_capabilities
    assert @capabilities.smart_capabilities == []
    assert @smart_capabilities.smart_capabilities == ['launch-ehr', 'launch-standalone']
  end

  def test_supported_profiles
    expected_profiles = [
      'http://hl7.org/fhir/us/core/StructureDefinition/us-core-condition',
      'http://hl7.org/fhir/us/core/StructureDefinition/pediatric-bmi-for-age',
      'http://hl7.org/fhir/us/core/StructureDefinition/pediatric-weight-for-height'
    ]

    assert_equal(expected_profiles, @capabilities.supported_profiles)
  end

  def test_search_documented
    assert @capabilities.search_documented?('Patient')
    refute @capabilities.search_documented?('Condition')
    refute @capabilities.search_documented?('Observation')
  end

  def test_supported_search_params
    assert_equal ['_id', 'birthdate'], @capabilities.supported_search_params('Patient')
    assert_equal [], @capabilities.supported_search_params('Condition')
    assert_equal [], @capabilities.supported_search_params('Location')
  end

  def test_supported_revincludes
    assert_equal ['Provenance:target', 'Condition:subject'], @capabilities.supported_revincludes('Patient')
    assert_equal ['*'], @capabilities.supported_revincludes('Condition')
    assert_equal [], @capabilities.supported_revincludes('Observation')
    assert_equal [], @capabilities.supported_revincludes('Location')
  end

  def test_revinclude_supported
    assert @capabilities.revinclude_supported?('Patient', 'Provenance:target')
    assert @capabilities.revinclude_supported?('Patient', 'Condition:subject')
    assert @capabilities.revinclude_supported?('Condition', 'Provenance:target')
    refute @capabilities.revinclude_supported?('Observation', 'Provenance:target')
    refute @capabilities.revinclude_supported?('Location', 'Provenance:target')
  end

  def test_supported_includes
    assert_equal ['*'], @capabilities.supported_includes('Patient')
    assert_equal ['Practitioner:asserter', 'Patient:subject'], @capabilities.supported_includes('Condition')
    assert_equal [], @capabilities.supported_includes('Observation')
    assert_equal [], @capabilities.supported_includes('Location')
  end

  def test_include_supported
    assert @capabilities.include_supported?('Condition', 'Practitioner:asserter')
    assert @capabilities.include_supported?('Condition', 'Patient:subject')
    assert @capabilities.include_supported?('Patient', 'Practitioner:asserter')
    refute @capabilities.include_supported?('Observation', 'Provenance:target')
    refute @capabilities.include_supported?('Location', 'Provenance:target')
  end
end
