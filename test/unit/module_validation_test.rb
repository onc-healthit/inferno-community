# frozen_string_literal: true

require_relative '../test_helper'

# These test requirements of modules that are currently loaded
class ModuleValidationTest < MiniTest::Test
  def setup
    @modules = Inferno::Module.available_modules&.values
  end

  # Within any module, multiple sequences with the same test_id should not ever be loaded.
  # Note that we currently allow duplicates if the same sequence is referenced multiple times.
  def test_no_duplicate_test_ids
    @modules&.each do |inferno_module|
      unique_sequences = inferno_module.sequences.uniq
      test_ids = unique_sequences.flat_map(&:tests).map { |test| test[:test_id] }
      duplicate_id = test_ids.detect { |t| test_ids.count(t) > 1 }
      assert duplicate_id.nil?, "Found at least one duplicated test_id in module #{inferno_module.name}: #{duplicate_id}."
    end
  end
end
