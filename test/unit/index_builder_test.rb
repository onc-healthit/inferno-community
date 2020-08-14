# frozen_string_literal: true

require 'json'
require_relative '../test_helper'

describe Inferno::IndexBuilder do
  before do
    @index_builder = Inferno::IndexBuilder.new
  end

  describe 'Index produced when no files are indexed' do
    it 'Contains "index-version" and "files" properties' do
      @index_builder.start
      index = JSON.parse(@index_builder.build)

      assert_equal 1, index['index-version']
      assert_equal [], index['files']
    end
  end

  describe 'IndexBuilder.see_file' do
    it 'Ignores files that do not have .json extension' do
      @index_builder.start
      @index_builder.see_file('foo.json', '{"resourceType": "Patient"}')
      @index_builder.see_file('bar.txt', '{"resourceType": "MedicationRequest"}')
      index = JSON.parse(@index_builder.build)

      assert_equal [
        {
          'filename' => 'foo.json',
          'resourceType' => 'Patient'
        }
      ], index['files']
    end

    it 'Ignores files that cannot be parsed (invalid JSON)' do
      @index_builder.start
      @index_builder.see_file('invalid.json', '<NotJSON></NotJSON>')
      index = JSON.parse(@index_builder.build)

      assert_equal [], index['files']
    end
  end

  describe 'IndexBuilder.execute' do
    it 'Can index a directory and returns whether an .index.json was created' do
      fixture_path = find_fixture_directory
      folder = File.join(fixture_path, 'sample_ig')
      index_file = File.join(folder, '.index.json')

      # .index.json doesn't exist, so IndexBuilder will create an .index.json
      assert !File.exist?(index_file)
      assert @index_builder.execute(folder)

      # .index.json now exists, so IndexBuilder will not create an .index.json
      assert File.exist?(index_file)
      assert !@index_builder.execute(folder)

      index = JSON.parse(File.read(index_file))

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

      File.delete(index_file)
    end
  end
end
