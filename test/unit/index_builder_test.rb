# frozen_string_literal: true

require 'json'
require 'tmpdir'
require_relative '../test_helper'

describe Inferno::IndexBuilder do
  describe 'when IndexBuilder is given an empty directory' do
    it 'should raise an ArgumentError for not having a package.json' do
      Dir.mktmpdir do |dir|
        assert_raises(ArgumentError) { Inferno::IndexBuilder.new(dir) }
      end
    end
  end

  describe 'when IndexBuilder is given a package with no index' do
    it 'should be considered indexed only after an index has been built' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'package.json'), '{}')
        index_builder = Inferno::IndexBuilder.new(dir)

        refute_predicate index_builder, :indexed?
        index_builder.build
        assert_predicate index_builder, :indexed?
      end
    end

    it 'should build an index with "index-version" and "files" properties' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'package.json'), '{}')
        Inferno::IndexBuilder.new(dir).build do |contents|
          index = JSON.parse(contents)

          assert_equal 1, index['index-version']
          assert_equal [], index['files']
        end
      end
    end
  end

  describe 'when IndexBuilder is given a package with an index' do
    it 'should return immediately and not overwrite the existing index' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write('package.json', '{}')
          File.write('.index.json', 'DO NOT OVERWRITE')
        end

        Inferno::IndexBuilder.new(dir).build do
          raise StandardError, 'should not reach'
        end

        Inferno::IndexBuilder.new(dir).build
        assert_equal 'DO NOT OVERWRITE', File.read(File.join(dir, '.index.json'))
      end
    end
  end

  describe 'when IndexBuilder is given a package containing multiple file types' do
    it 'ignores files that do not have the .json extension or have an invalid "resourceType"' do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.write('package.json', '{}')
          File.write('foo.json', '{"resourceType": "Patient"}')
          File.write('bar.txt', '{"resourceType": "MedicationRequest"}')
          File.write('baz.json', '{"resourceType": true}')
          File.write('missing.json', '{}')
        end

        Inferno::IndexBuilder.new(dir).build do |contents|
          index = JSON.parse(contents)

          assert_equal [
            {
              'filename' => 'foo.json',
              'resourceType' => 'Patient'
            }
          ], index['files']
        end
      end
    end
  end

  describe 'when IndexBuilder is given the sample_ig package' do
    it 'should yield the correct index contents but not write it to disk' do
      fixture_path = find_fixture_directory
      folder = File.join(fixture_path, 'sample_ig')

      Inferno::IndexBuilder.new(folder).build do |contents|
        index = JSON.parse(contents)

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

      refute_predicate Inferno::IndexBuilder.new(folder), :indexed?
    end
  end
end
