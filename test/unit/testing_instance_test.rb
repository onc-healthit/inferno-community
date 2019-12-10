# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/inferno/app/models/testing_instance'

describe Inferno::Models::TestingInstance do
  before do
    @instance = Inferno::Models::TestingInstance.create(selected_module: 'uscore_v3.1.0')
  end

  describe '#conformance_supported?' do
    before do
      @conformance = FHIR::DSTU2.from_contents(load_fixture(:conformance_statement))
    end

    it 'returns true if the resource is supported' do
      Inferno::Models::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: @conformance.as_json
      )

      assert @instance.conformance_supported?(:Patient)
    end

    it 'returns true if the resource and operations are supported' do
      Inferno::Models::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: @conformance.as_json
      )

      assert @instance.conformance_supported?(:Patient, [:read])
      assert @instance.conformance_supported?(:Patient, [:read, :search, :history])
    end

    it 'returns false if the resource is not supported' do
      @conformance.rest.first.resource.reject! { |r| r.type == 'Patient' }
      Inferno::Models::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: @conformance.as_json
      )

      assert !@instance.conformance_supported?(:Patient)
      assert !@instance.conformance_supported?(:Patient, [:read])
      assert !@instance.conformance_supported?(:Patient, [:read, :search, :history])
    end

    it 'returns false if the operations are not supported' do
      @conformance.rest.first.resource.find { |r| r.type == 'Patient' }.interaction.reject! { |i| i.code == 'read' }
      Inferno::Models::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: @conformance.as_json
      )

      assert @instance.conformance_supported?(:Patient)
      assert !@instance.conformance_supported?(:Patient, [:read])
      assert !@instance.conformance_supported?(:Patient, [:read, :search])
    end
  end

  describe '#fhir_version_match?' do
    fhir_versions = [:dstu2, :stu3]

    it 'returns true if no version is set' do
      @instance.instance_variable_set(:@module, OpenStruct.new(fhir_version: nil))
      assert @instance.fhir_version_match?(fhir_versions)
    end

    it 'returns true if the versions match' do
      @instance.instance_variable_set(:@module, OpenStruct.new(fhir_version: 'dstu2'))
      assert @instance.fhir_version_match?(fhir_versions)
    end

    it 'returns false if the versions do not match' do
      @instance.instance_variable_set(:@module, OpenStruct.new(fhir_version: 'r4'))
      assert !@instance.fhir_version_match?(fhir_versions)
    end
  end

  describe '#patient_id' do
    it 'returns the id of the Patient reference which was created first' do
      10.times do |index|
        Inferno::Models::ResourceReference.create(
          resource_type: 'Patient',
          resource_id: index.to_s,
          testing_instance: @instance
        )
      end

      assert_equal '0', @instance.patient_id
    end
  end

  describe '#patient_id=' do
    it 'sets the patient id' do
      @instance.patient_id = '123'

      assert_equal '123', @instance.patient_id

      @instance.patient_id = '456'

      assert_equal '456', @instance.patient_id
    end
  end
end

class TestingInstanceTest < MiniTest::Test
  def setup
    @patient_id1 = '1'
    @patient_id2 = '2'
    @testing_instance = Inferno::Models::TestingInstance.new
    @testing_instance.resource_references << Inferno::Models::ResourceReference.new(
      resource_type: 'Patient',
      resource_id: @patient_id1
    )
    @testing_instance.save!
  end

  def test_patient_id_assignment
    assert(@testing_instance.resource_references.length == 1)

    @testing_instance.patient_id = @patient_id2

    assert(@testing_instance.patient_id == @patient_id2)
    assert(@testing_instance.resource_references.length == 1)
    assert(@testing_instance.resource_references.first.resource_id == @patient_id2)
  end

  def test_patient_id_reassignment
    resource_references = @testing_instance.resource_references
    assert(resource_references.length == 1)

    @testing_instance.patient_id = @patient_id1

    assert(@testing_instance.resource_references == resource_references)
  end
end
