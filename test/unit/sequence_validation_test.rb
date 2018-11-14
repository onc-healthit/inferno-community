require File.expand_path '../../test_helper.rb', __FILE__

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

    test_list = @sequences.map do |sequence|
      test_list = sequence.tests.map {|test| test[:sequence] = sequence.name; test}
    end.flatten

    test_list.select!{ |test| !excluded_tests.include?(test[:name])}

    incomplete_metadata_tests = test_list.select{ |test| test[:name].nil? ||
      test[:description].nil? ||
      !valid_uri?(test[:url]) ||
      test[:test_id].nil?
      # || test[:ref].nil? # no refs yet
    }

    assert incomplete_metadata_tests.empty?, "Found #{incomplete_metadata_tests.length} tests with incomplete metadata."\
      "First: #{!incomplete_metadata_tests.empty? && incomplete_metadata_tests.first[:sequence]}: #{!incomplete_metadata_tests.empty? && incomplete_metadata_tests.first[:name]}"
  end

  def test_ordered_sequences

    assert Inferno::Sequence::SequenceBase.ordered_sequences.uniq.length == Inferno::Sequence::SequenceBase.ordered_sequences.length, 'There are duplicate sequences in SequenceBase.ordered_sequences.'
    assert (Inferno::Sequence::SequenceBase.subclasses.select{|seq| !seq.inactive?}-Inferno::Sequence::SequenceBase.ordered_sequences).blank?  && (Inferno::Sequence::SequenceBase.ordered_sequences-Inferno::Sequence::SequenceBase.subclasses.select{|seq| !seq.inactive?}).blank?, 'SequenceBase.ordered_sequences does not contain correct subclasses.  Please update method in SequenceBase.'
  end

  def test_ids_sequential

    # tests ids must be sequential without any holes
    # test ids must be 2 digits long
    # if a test is no longer valid, we should add a deprecated flag

    errors = []

    Inferno::Sequence::SequenceBase.subclasses.each do |seq|
      ids = seq.tests.reduce([]) do |out, hash|
        if hash[:test_id].nil?
          out
        else
          out << hash[:test_id].scan(/\d{2}/)[0, 2].join.to_i
        end
      end.sort
      all_in_order = ids.each_cons(2).all? { |x,y| y == x + 1 }
      errors << seq.sequence_name unless all_in_order and ids.first != 0
    end

    assert errors.empty?, "Sequence(s) #{errors.join(',')} do not have incrementing test id numbers"\
                          ' or has an id which isn\'t two digits.  Add deprecated flag if a test is no longer needed.'

  end

end
