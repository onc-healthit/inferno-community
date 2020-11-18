# frozen_string_literal: true

require_relative '../test_helper'

class TerminologyTest < Minitest::Test
  NARRATIVE_STATUS_VS = 'http://hl7.org/fhir/us/core/ValueSet/us-core-narrative-status'
  BIRTH_SEX_VS = 'http://hl7.org/fhir/us/core/ValueSet/birthsex'

  def setup
    # Load a minimal set of validators
    # Note: these could already be loaded through sequence_base
    Inferno::Terminology.load_validators('test/fixtures/validators')
  end

  def test_validator_hash_counts
    assert_equal 2, Inferno::Terminology.loaded_validators[NARRATIVE_STATUS_VS]
    assert_equal 3, Inferno::Terminology.loaded_validators[BIRTH_SEX_VS]
  end

  def test_validators_set_on_structure_definition
    refute_nil FHIR::DSTU2::StructureDefinition.vs_validators[NARRATIVE_STATUS_VS], "No validator function set on StructureDefinition for the #{NARRATIVE_STATUS_VS} valueset"

    refute_nil FHIR::DSTU2::StructureDefinition.vs_validators[BIRTH_SEX_VS], "No validator function set on StructureDefinition for the #{BIRTH_SEX_VS} valueset"
  end
end
