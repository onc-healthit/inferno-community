# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/app/utils/terminology'
require_relative '../../lib/app/utils/valueset'

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

  def test_create_bloom_validators
    expected_birthsex_manifest = {
      url: 'http://hl7.org/fhir/us/core/ValueSet/birthsex',
      file: 'hl7_org_fhir_us_core_ValueSet_birthsex.msgpack',
      count: 3,
      type: 'bloom',
      code_systems: ['http://terminology.hl7.org/CodeSystem/v3-AdministrativeGender', 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor']
    }

    expected_narrative_status_manifest = {
      url: 'http://hl7.org/fhir/us/core/ValueSet/us-core-narrative-status',
      file: 'hl7_org_fhir_us_core_ValueSet_us-core-narrative-status.msgpack',
      count: 2,
      type: 'bloom',
      code_systems: ['http://hl7.org/fhir/narrative-status']
    }

    file_write_stub = proc do |filename, yaml|
      assert filename == 'resources/terminology/validators/bloom/manifest.yml'
      manifest_info = YAML.safe_load(yaml, [Symbol])
      assert manifest_info.count == 2
      birthsex_manifest = manifest_info.find { |info| info[:url] == 'http://hl7.org/fhir/us/core/ValueSet/birthsex' }
      assert birthsex_manifest == expected_birthsex_manifest
      narrative_status_manifest = manifest_info.find { |info| info[:url] == 'http://hl7.org/fhir/us/core/ValueSet/us-core-narrative-status' }
      assert narrative_status_manifest == expected_narrative_status_manifest
    end

    save_bloom_to_file_stub = proc do |codeset, filename|
      if filename == 'resources/terminology/validators/bloom/hl7_org_fhir_us_core_ValueSet_birthsex.msgpack'
        assert codeset.count == 3
        assert(codeset.any? { |code| (code[:system] == 'http://terminology.hl7.org/CodeSystem/v3-AdministrativeGender' && code[:code] == 'F') })
        assert(codeset.any? { |code| (code[:system] == 'http://terminology.hl7.org/CodeSystem/v3-AdministrativeGender' && code[:code] == 'M') })
        assert(codeset.any? { |code| (code[:system] == 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor') && (code[:code] == 'UNK') })
      end
    end
    Inferno::Terminology.known_valuesets.clear
    Inferno::Terminology.register_umls_db('umls.db')
    Inferno::Terminology.load_valuesets_from_directory('test/fixtures/validators', true)
    File.stub :write, file_write_stub do
      Inferno::Terminology.stub :save_bloom_to_file, save_bloom_to_file_stub do
        Inferno::Terminology.create_validators(type: :bloom)
      end
    end
  end

  def test_create_csv_validators
    expected_birthsex_manifest = {
      url: 'http://hl7.org/fhir/us/core/ValueSet/birthsex',
      file: 'hl7_org_fhir_us_core_ValueSet_birthsex.csv',
      count: 3,
      type: 'csv',
      code_systems: ['http://terminology.hl7.org/CodeSystem/v3-AdministrativeGender', 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor']
    }

    expected_narrative_status_manifest = {
      url: 'http://hl7.org/fhir/us/core/ValueSet/us-core-narrative-status',
      file: 'hl7_org_fhir_us_core_ValueSet_us-core-narrative-status.csv',
      count: 2,
      type: 'csv',
      code_systems: ['http://hl7.org/fhir/narrative-status']
    }

    file_write_stub = proc do |filename, yaml|
      assert filename == 'resources/terminology/validators/csv/manifest.yml'
      manifest_info = YAML.safe_load(yaml, [Symbol])
      assert manifest_info.count == 2
      birthsex_manifest = manifest_info.find { |info| info[:url] == 'http://hl7.org/fhir/us/core/ValueSet/birthsex' }
      assert birthsex_manifest == expected_birthsex_manifest
      narrative_status_manifest = manifest_info.find { |info| info[:url] == 'http://hl7.org/fhir/us/core/ValueSet/us-core-narrative-status' }
      assert narrative_status_manifest == expected_narrative_status_manifest
    end
    Inferno::Terminology.known_valuesets.clear
    Inferno::Terminology.register_umls_db('umls.db')
    Inferno::Terminology.load_valuesets_from_directory('test/fixtures/validators', true)
    File.stub :write, file_write_stub do
      Inferno::Terminology.stub :save_bloom_to_file, true do
        Inferno::Terminology.create_validators(type: :csv)
      end
    end
  end

  def test_create_validators_with_selected_module
    file_write_stub = proc do |filename, yaml|
      assert filename == 'resources/terminology/validators/bloom/manifest.yml'
      manifest_info = YAML.safe_load(yaml, [Symbol])
      assert manifest_info.count == 2
    end

    Inferno::Terminology.known_valuesets.clear
    Inferno::Terminology.register_umls_db('umls.db')
    Inferno::Terminology.load_valuesets_from_directory('test/fixtures/validators', true)
    File.stub :write, file_write_stub do
      Inferno::Terminology.stub :save_bloom_to_file, true do
        Inferno::Terminology.create_validators(type: :bloom, selected_module: 'uscore_v3.1.0')
      end
    end
  end
end
