# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __dir__

class TestInstanceTest < MiniTest::Test
  def setup
    @instance = Inferno::Models::TestingInstance.create(selected_module: 'us_core_v301')
  end

  def test_conformance_supported
    conformance = FHIR::DSTU2.from_contents(load_fixture(:conformance_statement))
    Inferno::Models::ServerCapabilities.create(
      testing_instance_id: @instance.id,
      capabilities: conformance.as_json
    )

    assert @instance.conformance_supported?(:Patient, [:read])
    assert @instance.conformance_supported?(:Patient, [:read, :search, :history])
    assert @instance.conformance_supported?(:Patient)
    assert !@instance.conformance_supported?(:NoSuchResource, [:read])
    assert !@instance.conformance_supported?(:Patient, [:NoSuchOperation])
  end

  def test_conformance_supported_no_patient
    conformance = FHIR::DSTU2.from_contents(load_fixture(:conformance_statement))
    conformance.rest.first.resource.reject! { |r| r.type == 'Patient' }
    Inferno::Models::ServerCapabilities.create(
      testing_instance_id: @instance.id,
      capabilities: conformance.as_json
    )

    assert !@instance.conformance_supported?(:Patient, [:read])
    assert !@instance.conformance_supported?(:Patient, [:read, :search, :history])
    assert !@instance.conformance_supported?(:Patient)
    assert @instance.conformance_supported?(:Observation, [:read])
  end

  def test_conformance_supported_no_patient_read
    conformance = FHIR::DSTU2.from_contents(load_fixture(:conformance_statement))
    conformance.rest.first.resource.find { |r| r.type == 'Patient' }.interaction.reject! { |i| i.code == 'read' }
    Inferno::Models::ServerCapabilities.create(
      testing_instance_id: @instance.id,
      capabilities: conformance.as_json
    )

    assert @instance.conformance_supported?(:Patient)
    assert @instance.conformance_supported?(:Patient, [:search])
    assert !@instance.conformance_supported?(:Patient, [:read])
    assert !@instance.conformance_supported?(:Patient, [:read, :search])
    assert @instance.conformance_supported?(:Observation, [:read])
  end
end
