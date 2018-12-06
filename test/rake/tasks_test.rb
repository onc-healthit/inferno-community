# frozen_string_literal: true

require_relative '../test_helper'
require 'rake'

class TasksTest < MiniTest::Test
  def setup
    Rake.application.load_rakefile
  end

  def test_csv_export
    Inferno::Module.available_modules.keys.each do |mod|
      Rake::Task['inferno:tests_to_csv'].invoke(mod)
      Rake::Task['inferno:tests_to_csv'].reenable
    end
  end
end