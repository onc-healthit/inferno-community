require File.expand_path '../../test_helper.rb', __FILE__

# These test structure and metadata within sequences but do not execute them.
# Sequence execution tests are in the /test/sequence directory.

class SequenceValidationTest < MiniTest::Unit::TestCase

  def valid_url?(url)
    !(url =~ /\A#{URI::regexp(['http', 'https'])}\z/).nil?
  end

  def setup
    @sequences = SequenceBase.subclasses
  end

  def test_metadata

    # additonal requiremetns
    excluded_tests = ['Patient has address', 'Patient has telecom', 'Token expiration']

    # questionable requirements
    excluded_tests << 'Patient supports $everything operation'

    # not yet finished
    AdditionalResourcesSequence.tests.each { |test| excluded_tests << test[:name]}

    test_list = @sequences.map do |sequence|
      test_list = sequence.tests.map {|test| test[:sequence] = sequence.name; test}
    end.flatten

    test_list.select!{ |test| !excluded_tests.include?(test[:name])}

    incomplete_metadata_tests = test_list.select{ |test| test[:name].nil? || test[:description].nil? || !valid_url?(test[:url])}

    assert incomplete_metadata_tests.empty?, "Found #{incomplete_metadata_tests.length} tests with incomplete metadata."\
      "First: #{!incomplete_metadata_tests.empty? && incomplete_metadata_tests.first[:sequence]}: #{!incomplete_metadata_tests.empty? && incomplete_metadata_tests.first[:name]}"
  end

  def test_ordered_sequences

    assert SequenceBase.ordered_sequences.uniq.length == SequenceBase.ordered_sequences.length, 'There are duplicate sequences in SequenceBase.ordered_sequences.'
    assert (SequenceBase.subclasses-SequenceBase.ordered_sequences).blank?  && (SequenceBase.ordered_sequences-SequenceBase.subclasses).blank?, 'SequenceBase.ordered_sequences does not contain correct subclasses.  Please update method in SequenceBase.'
  end

end
