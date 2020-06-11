# frozen_string_literal: true

require_relative '../test_helper'

class TerminologyTest < Minitest::Test
  NARRATIVE_STATUS_VS = 'http://hl7.org/fhir/us/core/ValueSet/us-core-narrative-status'
  BIRTH_SEX_VS = 'http://hl7.org/fhir/us/core/ValueSet/birthsex'
  ADMIN_GENDER_CS = 'http://terminology.hl7.org/CodeSystem/v3-AdministrativeGender'
  NF_CS = 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor'

  def setup
    # Load a minimal set of validators
    # Note: these could already be loaded through sequence_base
    Inferno::Terminology.load_validators('test/fixtures/validators')
  end

  def test_validator_hash_counts
    assert_equal 2, Inferno::Terminology.loaded_validators[NARRATIVE_STATUS_VS][:count]
    assert_equal 3, Inferno::Terminology.loaded_validators[BIRTH_SEX_VS][:count]
  end

  def test_validators_set_on_structure_definition
    refute_nil FHIR::DSTU2::StructureDefinition.vs_validators[NARRATIVE_STATUS_VS], "No validator function set on StructureDefinition for the #{NARRATIVE_STATUS_VS} valueset"

    refute_nil FHIR::DSTU2::StructureDefinition.vs_validators[BIRTH_SEX_VS], "No validator function set on StructureDefinition for the #{BIRTH_SEX_VS} valueset"
  end

  def test_validate_code
    # Valid code, optional codesystem
    assert Inferno::Terminology.validate_code(valueset_url: BIRTH_SEX_VS,
                                              code: 'M',
                                              system: nil),
           'Validate code helper should return true for a valid code with a nil codesystem'
    assert Inferno::Terminology.validate_code(valueset_url: BIRTH_SEX_VS,
                                              code: 'M',
                                              system: ADMIN_GENDER_CS),
           'Validate code helper should return true for a valid code with a provided codesystem'

    # Invalid code, optional codesystem
    refute Inferno::Terminology.validate_code(valueset_url: BIRTH_SEX_VS,
                                              code: 'R',
                                              system: nil),
           'Validate code helper should return false for an invalid code with a nil codesystem'
    refute Inferno::Terminology.validate_code(valueset_url: BIRTH_SEX_VS,
                                              code: 'R',
                                              system: ADMIN_GENDER_CS),
           'Validate code helper should return false for an invalid code with a provided codesystem'

    refute Inferno::Terminology.validate_code(valueset_url: BIRTH_SEX_VS,
                                              code: 'M',
                                              system: NF_CS),
           'Validate code helper should return false for a valid code, but the wrong codesystem from the valueset'
    refute Inferno::Terminology.validate_code(valueset_url: BIRTH_SEX_VS,
                                              code: 'M',
                                              system: 'http://fake-cs'),
           'Validate code helper should return false for a valid code, but a fake codesystem'
    refute Inferno::Terminology.validate_code(valueset_url: BIRTH_SEX_VS,
                                              code: 'R',
                                              system: 'http://fake-cs'),
           'Validate code helper should return false for an invalid code with an invalid codesystem'
    # valid code, no valueset url, codesystem URL instead
    assert Inferno::Terminology.validate_code(valueset_url: nil,
                                              code: 'M',
                                              system: ADMIN_GENDER_CS),
           'Validate code helper should return true for a valid code with a provided codesystem'
    # invalid code, no valueset url, codesystem URL instead
    refute Inferno::Terminology.validate_code(valueset_url: nil,
                                              code: 'R',
                                              system: ADMIN_GENDER_CS),
           'Validate code helper should return false for an invalid code with a provided codesystem'

    # An invalid valueset should raise an error
    assert_raises Inferno::Terminology::UnknownValueSetException do
      Inferno::Terminology.validate_code(valueset_url: 'http://a-fake-valueset', code: 'M', system: 'http://terminology.hl7.org/CodeSystem/v3-AdministrativeGender')
    end
    assert_raises Inferno::Terminology::UnknownValueSetException do
      Inferno::Terminology.validate_code(valueset_url: 'http://a-fake-valueset', code: 'M', system: nil)
    end
  end
end
