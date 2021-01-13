# frozen_string_literal: true

require_relative '../test_helper'

describe Inferno::Terminology::Codesystem do
  before do
    @codesystem = Inferno::Terminology::Codesystem.new(FHIR::Json.from_json(File.read('test/fixtures/terminology/sample_cs.json')))
  end

  it 'Should pass back all the codes in the system, including nested codes, when asked' do
    all_codes = @codesystem.filter_codes
    assert_equal 6, all_codes.size
    all_codes.each do |code|
      assert_equal 'http://example.com/sample-cs', code[:system]
      refute_empty code[:code]
    end
  end

  it 'Should only pass back the nested codes when an is-a filter is applied' do
    filter = FHIR::ValueSet::Compose::Include::Filter.new(property: 'concept',
                                                          op: 'is-a',
                                                          value: 'nested_code')
    filtered_codes = @codesystem.filter_codes(filter)
    assert_equal 3, filtered_codes.size
    filtered_codes.each do |code|
      assert_equal 'http://example.com/sample-cs', code[:system]
      refute_empty code[:code]
      assert code[:code].match?(/nested_/), 'Code is not one of the nested codes'
    end
  end

  it 'should raise an error when an unsupported filter is applied' do
    filter = FHIR::ValueSet::Compose::Include::Filter.new(property: 'concept',
                                                          op: 'part-of',
                                                          value: 'nested_code')
    assert_raises(Inferno::Terminology::ValueSet::FilterOperationException) { @codesystem.filter_codes(filter) }
  end
end
