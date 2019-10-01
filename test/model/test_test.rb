# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __dir__

Test = Inferno::Sequence::Test

describe Test do
  NAME = 'NAME'
  INDEX = 1
  PREFIX = 'PREFIX'
  TEST_ID = 123
  LINK = 'LINK'
  REF = 'REF'
  DESCRIPTION = 'DESCRIPTION'

  before do
    @base_test = Test.new(NAME, INDEX, PREFIX, &proc {})
  end

  describe '.initialize' do
    it 'creates an Test instance' do
      assert @base_test.instance_of? Test
    end
  end

  describe '#id' do
    it 'returns nil if no id has been set' do
      assert @base_test.id.nil?
    end

    it 'sets the id with a prefix' do
      @base_test.id(TEST_ID)
      assert @base_test.id == "#{PREFIX}-#{TEST_ID}"
    end
  end

  describe '#link' do
    it 'returns nil if no link has been set' do
      assert @base_test.link.nil?
    end

    it 'sets and returns the link' do
      @base_test.link(LINK)
      assert @base_test.link == LINK
    end
  end

  describe '#ref' do
    it 'returns nil if no ref has been set' do
      assert @base_test.ref.nil?
    end

    it 'sets and returns the ref' do
      @base_test.ref(REF)
      assert @base_test.ref == REF
    end
  end

  describe '#desc' do
    it 'returns nil if no description has been set' do
      assert @base_test.desc.nil?
    end

    it 'sets and returns the description' do
      @base_test.desc(DESCRIPTION)
      assert @base_test.desc == DESCRIPTION
    end
  end

  describe '#versions' do
    it 'returns an empty array if no versions have been set' do
      assert @base_test.versions == []
    end

    it 'sets and returns the versions' do
      versions = :version
      @base_test.versions(versions)
      assert @base_test.versions == [versions]
    end
  end

  describe '#optional' do
    it 'sets a test as optional' do
      @base_test.optional
      assert @base_test.optional?
    end
  end

  describe '#optional?' do
    it 'returns whether a test is optional' do
      assert !@base_test.optional?
      @base_test.optional
      assert @base_test.optional?
    end
  end

  describe '#required?' do
    it 'returns whether a test is required' do
      assert @base_test.required?
      @base_test.optional
      assert !@base_test.required?
    end
  end

  describe '#metadata_hash' do
    it 'returns a metadata hash' do
      @base_test.id(TEST_ID)
      @base_test.desc(DESCRIPTION)
      @base_test.link(LINK)
      @base_test.ref(REF)
      assert @base_test.metadata_hash == {
        test_id: "#{PREFIX}-#{TEST_ID}",
        name: NAME,
        description: DESCRIPTION,
        required: true,
        url: LINK,
        ref: REF
      }
    end
  end
end
