require File.expand_path '../../test_helper.rb', __FILE__

class TestInstanceTest < MiniTest::Unit::TestCase

  def setup
    @instance = Inferno::Models::TestingInstance.create
  end

  def test_conformance_supported
    conformance = FHIR::DSTU2.from_contents(load_fixture(:conformance_statement))
    @instance.save_supported_resources(conformance)
    assert @instance.conformance_supported?(:Patient, [:read])
    assert @instance.conformance_supported?(:Patient, [:read, :search, :history])
    assert @instance.conformance_supported?(:Patient)
    assert !@instance.conformance_supported?(:NoSuchResource, [:read])
    assert !@instance.conformance_supported?(:Patient, [:NoSuchOperation])
  end

  def test_conformance_supported_no_patient
    conformance = FHIR::DSTU2.from_contents(load_fixture(:conformance_statement))
    conformance.rest.first.resource.reject!{|r| r.type == 'Patient'}
    @instance.save_supported_resources(conformance)

    assert !@instance.conformance_supported?(:Patient, [:read])
    assert !@instance.conformance_supported?(:Patient, [:read, :search, :history])
    assert !@instance.conformance_supported?(:Patient)
    assert @instance.conformance_supported?(:Observation, [:read])

  end

  def test_conformance_supported_no_patient_read
    conformance = FHIR::DSTU2.from_contents(load_fixture(:conformance_statement))
    conformance.rest.first.resource.find{|r| r.type == 'Patient'}.interaction.reject!{|i| i.code == 'read'}
    @instance.save_supported_resources(conformance)

    assert @instance.conformance_supported?(:Patient)
    assert @instance.conformance_supported?(:Patient, [:search])
    assert !@instance.conformance_supported?(:Patient, [:read])
    assert !@instance.conformance_supported?(:Patient, [:read, :search])
    assert @instance.conformance_supported?(:Observation, [:read])

  end
end
