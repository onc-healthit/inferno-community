# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __dir__

class TestInstanceTest < MiniTest::Test
  def setup
    @instance = Inferno::Models::TestingInstance.create(selected_module: 'uscore_v3.0.0')
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

  def test_fhir_version_match
    fhir_versions = [:dstu2, :stu3]

    # Returns true if no version is set
    @instance.instance_variable_set(:@module, OpenStruct.new(fhir_version: nil))
    assert @instance.fhir_version_match?(fhir_versions)

    # Returns true if version matches
    @instance.instance_variable_set(:@module, OpenStruct.new(fhir_version: 'dstu2'))
    assert @instance.fhir_version_match?(fhir_versions)

    # Returns false if version doesn't match
    @instance.instance_variable_set(:@module, OpenStruct.new(fhir_version: 'r4'))
    assert !@instance.fhir_version_match?(fhir_versions)
  end
end
