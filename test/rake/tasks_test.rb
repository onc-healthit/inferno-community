# frozen_string_literal: true

require_relative '../test_helper'
require 'rake'

class TasksTest < MiniTest::Test
  RESPONSE_HEADERS = { 'content-type' => 'application/json+fhir;charset=UTF-8' }.freeze

  def setup
    Rake.application.load_rakefile
    @conformance = load_json_fixture(:conformance_statement)

  end

  def test_csv_export
    Inferno::Module.available_modules.keys.each do |mod|
      Rake::Task['inferno:tests_to_csv'].invoke(mod)
      Rake::Task['inferno:tests_to_csv'].reenable
    end
  end

  def test_execute
    WebMock.reset!
    stub_request(:get, /example/)
        .to_return(status: 200, body: @conformance.to_json, headers: RESPONSE_HEADERS)

    Rake::Task['inferno:execute'].invoke('https://www.example.com', 'argonaut', 'ArgonautConformance')
  end
end