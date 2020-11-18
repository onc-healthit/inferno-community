# frozen_string_literal: true

require_relative '../test_helper'

# These test structure and metadata within sequences but do not execute them.
# Sequence execution tests are in the /test/sequence directory.
class SequenceValidationTest < MiniTest::Test
  def setup
    @sequences = Inferno::Sequence::SequenceBase.subclasses
  end

  def test_metadata
    # additonal requiremetns
    excluded_tests = ['Patient has address', 'Patient has telecom', 'Token expiration']

    # questionable requirements
    excluded_tests << 'Patient supports $everything operation'

    test_list = @sequences.flat_map do |sequence|
      sequence.tests.map { |test| test.metadata_hash.merge(sequence: sequence.name) }
    end

    test_list.reject! { |test| excluded_tests.include?(test[:name]) }

    incomplete_metadata_tests = test_list.select do |test|
      test[:name].nil? ||
        test[:description].nil? ||
        !valid_uri?(test[:url]) ||
        test[:test_id].nil?
    end

    empty = incomplete_metadata_tests.empty?
    assert empty, "Found #{incomplete_metadata_tests.length} tests with incomplete metadata."\
      "First: #{!empty && incomplete_metadata_tests.first[:sequence]}: #{!empty && incomplete_metadata_tests.first[:name]}"
  end

  def test_ordered_sequences
    instance = get_test_instance
    instance.selected_module = 'argonaut'
    my_module = instance.module
    my_module.test_sets.each do |_key, test_set|
      test_set.groups.each do |group|
        assert group.test_cases.uniq.length == group.test_cases.length, "There are duplicate sequences in the selected module: #{instance.selected_module}"
        group.test_cases.each do |test_case|
          assert test_case.sequence.ancestors.include?(Inferno::Sequence::SequenceBase), "#{test_case.sequence} should be a subclass of SequenceBase"
        end
      end
    end
  end

  def test_ids_sequential
    # tests ids must be sequential without any holes
    # test ids must be 2 digits long
    # if a test is no longer valid, we should add a deprecated flag

    errors = []

    Inferno::Sequence::SequenceBase.subclasses.each do |sequence|
      ids = sequence.tests.map(&:metadata_hash).reduce([]) do |out, metadata|
        if metadata[:test_id].nil?
          out
        else
          out << metadata[:test_id].scan(/\d{2}/)[0, 2].join.to_i
        end
      end.sort
      all_in_order = ids.each_cons(2).all? { |x, y| y == x + 1 }
      errors << sequence.sequence_name unless all_in_order && (ids.first != 0)
    end

    assert errors.empty?, "Sequence(s) #{errors.join(',')} do not have incrementing test id numbers"\
                          ' or has an id which isn\'t two digits.  Add deprecated flag if a test is no longer needed.'
  end
end
