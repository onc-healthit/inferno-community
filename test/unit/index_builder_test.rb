# frozen_string_literal: true

require 'json'
require 'tmpdir'
require_relative '../test_helper'

describe Inferno::IndexBuilder do
  describe 'An empty directory' do
    it 'Is indexed only once it has an .index.json' do
      Dir.mktmpdir do |dir|
        index_builder = Inferno::IndexBuilder.new(dir)

        assert !index_builder.indexed?
        File.write(File.join(dir, '.index.json'), '{"index-version": 1, "files": []}')
        assert index_builder.indexed?
      end
    end

    it 'Will have an index with "index-version" and "files" properties' do
      Dir.mktmpdir do |dir|
        index = JSON.parse(Inferno::IndexBuilder.new(dir).build)

        assert_equal 1, index['index-version']
        assert_equal [], index['files']
      end
    end
  end

  describe 'IndexBuilder for a directory containing multiple file types' do
    it 'Ignores files that do not have .json extension' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write('foo.json', '{"resourceType": "Patient"}')
          File.write('bar.txt', '{"resourceType": "MedicationRequest"}')
        end

        index = JSON.parse(Inferno::IndexBuilder.new(dir).build)

        assert_equal [
          {
            'filename' => 'foo.json',
            'resourceType' => 'Patient'
          }
        ], index['files']
      end
    end

    it 'Ignores files that do not have the "resourceType" property' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write('ignored.json', '{}')
        end

        index = JSON.parse(Inferno::IndexBuilder.new(dir).build)

        assert_equal [], index['files']
      end
    end
  end

  describe 'IndexBuilder.build' do
    it 'Returns the contents of an .index.json for the directory' do
      fixture_path = find_fixture_directory
      folder = File.join(fixture_path, 'sample_ig')

      index = JSON.parse(Inferno::IndexBuilder.new(folder).build)

      assert_equal [
        {
          'filename' => 'StructureDefinition-Patient.json',
          'resourceType' => 'StructureDefinition',
          'id' => 'Patient',
          'version' => '1.2.3',
          'url' => 'http://foo.bar/Patient',
          'kind' => 'resource',
          'type' => 'Patient'
        }
      ], index['files']
    end
  end
end
