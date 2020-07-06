# frozen_string_literal: true

require_relative '../test_helper'

# These test requirements of modules that are currently loaded
class ModuleValidationTest < MiniTest::Test
  def setup
    @modules = Inferno::Module.available_modules&.values
  end

  # Within any module, multiple sequences with the same test_id should not ever be loaded.
  # Note that we currently allow duplicates if the same sequence is referenced multiple times.
  # Also we ignore first children of a single parent
  def test_no_duplicate_test_ids
    errors = []
    @modules&.each do |inferno_module|
      unique_sequences = inferno_module.sequences.uniq do |seq|
        if seq.parent == Inferno::Sequence::SequenceBase
          seq
        else
          seq.parent
        end
      end
      test_ids = unique_sequences.flat_map(&:tests).map(&:id)
      duplicate_id = test_ids.detect { |t| test_ids.count(t) > 1 }
      errors << "#{inferno_module.name} (#{duplicate_id})" unless duplicate_id.nil?
    end

    assert errors.empty?, "Found at least one duplicate test_id in the following modules: #{errors.join(', ')}"
  end
end
