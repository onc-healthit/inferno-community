# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/app/models/testing_instance'

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