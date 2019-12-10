# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/inferno/app/models/server_capabilities'
require_relative '../../lib/inferno/app/models/testing_instance'

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
                { code: 'search-type' }
              ]
            },
            {
              type: 'Condition',
              profile: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-condition',
              interaction: [
                { code: 'delete' },
                { code: 'update' }
              ]
            },
            {
              type: 'Observation',
              supportedProfile: [
                'http://hl7.org/fhir/us/core/StructureDefinition/pediatric-bmi-for-age',
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
        interactions: ['history-instance', 'read', 'search', 'vread']
      },
      {
        resource_type: 'Condition',
        interactions: ['delete', 'update']
      },
      {
        resource_type: 'Observation',
        interactions: []
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
end
