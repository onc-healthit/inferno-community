# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __dir__

describe FHIR::Models do
  describe '#from_contents' do
    def assert_content_populated(bundle_resource)
      bundle_resource.entry.each do |entry|
        assert entry.source_contents.present?, "entry.source_contents not populated for #{entry}"
        assert_instance_of String, entry.source_contents
        assert entry.resource.source_contents.present?, "entry.resource.source_contents not populated for #{entry}"
        assert_instance_of String, entry.resource.source_contents
      end
    end

    it 'should set source_contents' do
      bundle_json = File.read('test/fixtures/bundle_1.json')
      bundle_resource = FHIR.from_contents(bundle_json)
      assert_content_populated(bundle_resource)
    end

    it 'should preserve primitive extensions in source_contents' do
      procedure_json = File.read('test/fixtures/procedure_primitive_extension.json')
      procedure_resource = FHIR.from_contents(procedure_json)

      assert procedure_resource.source_contents.include?('_performedDateTime'), 'Primitive extension key was lost'
      assert procedure_resource.source_contents.include?('http://hl7.org/fhir/StructureDefinition/data-absent-reason'), 'Primitive extension URL was lost'
    end

    it 'should preserve primitive extensions in bundled resources' do
      bundle_json = File.read('test/fixtures/bundle_primitive_extensions.json')
      bundle_resource = FHIR.from_contents(bundle_json)
      contained_patient = bundle_resource.entry.find { |e| e.resource.id == '1' }.resource
      contained_procedure = bundle_resource.entry.find { |e| e.resource.id == '2' }.resource

      assert contained_patient.source_contents.include?('_deceasedDateTime'), 'Primitive extension key was lost'
      assert contained_patient.source_contents.include?('http://hl7.org/fhir/StructureDefinition/data-absent-reason'), 'Primitive extension URL was lost'
      assert contained_procedure.source_contents.include?('_performedDateTime'), 'Primitive extension key was lost'
      assert contained_procedure.source_contents.include?('http://hl7.org/fhir/StructureDefinition/data-absent-reason'), 'Primitive extension URL was lost'
    end

    it 'should preserve primitive extensions in contained resources' do
      contained_json = File.read('test/fixtures/contained_resource.json')
      full_resource = FHIR.from_contents(contained_json)
      practitioner = full_resource.contained.first

      assert full_resource.source_contents.include?('_birthDate'), 'Primitive extension key was lost'
      assert full_resource.source_contents.include?('http://hl7.org/fhir/StructureDefinition/data-absent-reason'), 'Primitive extension URL was lost'

      assert practitioner.source_contents.include?('_birthDate'), 'Primitive extension key was lost'
      assert practitioner.source_contents.include?('http://hl7.org/fhir/StructureDefinition/data-absent-reason'), 'Primitive extension URL was lost'
    end
  end

  describe '#initialize' do
    it 'should set source_contents' do
      bundle_resource = FHIR::Bundle.new(
        resourceType: 'Bundle', entry:
        [
          { resource: { resourceType: 'Patient', id: 'a' } },
          { resource: { resourceType: 'Patient', id: 'b' } }
        ]
      )
      assert_content_populated(bundle_resource)
    end
  end
end
