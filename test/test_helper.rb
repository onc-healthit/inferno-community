# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
end

ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'webmock/minitest'
require 'rack/test'
test_log_filename = File.join('tmp', 'test.log')
FileUtils.rm test_log_filename if File.exist? test_log_filename

def create_assertion_report?
  ENV['ASSERTION_REPORT']&.downcase == 'true'
end

if create_assertion_report?
  require_relative './support/sequence_coverage_reporting'

  MiniTest.after_run { AssertionReporter.report }
end

require_relative '../lib/app'

def find_fixture_directory(test_directory = nil)
  test_directory ||=
    caller_locations
      .find { |trace| !trace.path.include? 'test_helper.rb' }
      .path
      .match(/(\/.*\/)\w+\.rb/)
      .captures
      .first

  fixture_directory = File.join(test_directory, 'fixtures')
  return fixture_directory if Dir.exist? fixture_directory

  test_directory = File.expand_path(File.join(test_directory, '..'))
  raise 'Unable to find fixture directory' if test_directory == '/'

  find_fixture_directory(test_directory)
end

def load_json_fixture(file)
  JSON.parse(load_fixture(file))
end

def load_fixture(file)
  fixture_path = find_fixture_directory
  File.read(File.join(fixture_path, "#{file}.json"))
end

def load_fixture_with_extension(file_name)
  fixture_path = find_fixture_directory
  File.read(File.join(fixture_path, file_name))
end

def valid_uri?(uri)
  !(uri =~ /\A#{URI.regexp(['http', 'https'])}\z/).nil?
end

def wrap_resources_in_bundle(resources, type: 'searchset')
  resources = [resources].flatten.compact
  # get the Bundle class from the same version of FHIR models
  bundle_class = resources.first.class.parent::Bundle
  bundle = bundle_class.new('id': 'foo', 'type': type)
  resources.each do |resource|
    bundle.entry << bundle_class::Entry.new
    bundle.entry.last.resource = resource
  end
  bundle
end

def get_resources_from_bundle(bundle, resource_type)
  resources = []
  bundle.entry.each do |entry|
    resources << entry.resource if entry.resource.resourceType == resource_type
  end
  resources
end

def get_test_instance(url: 'http://www.example.com',
                      client_name: 'Inferno',
                      base_url: 'http://localhost:4567',
                      client_endpoint_key: Inferno::SecureRandomBase62.generate(32),
                      client_id: SecureRandom.uuid,
                      oauth_authorize_endpoint: 'http://oauth_reg.example.com/authorize',
                      oauth_token_endpoint: 'http://oauth_reg.example.com/token',
                      scopes: 'launch openid patient/*.* profile',
                      selected_module: 'argonaut',
                      token: 'ACCESS_TOKEN')

  @instance = Inferno::Models::TestingInstance.new(url: url,
                                                   client_name: client_name,
                                                   base_url: base_url,
                                                   client_endpoint_key: client_endpoint_key,
                                                   client_id: client_id,
                                                   oauth_authorize_endpoint: oauth_authorize_endpoint,
                                                   oauth_token_endpoint: oauth_token_endpoint,
                                                   scopes: scopes,
                                                   selected_module: selected_module,
                                                   token: token)
end

def get_client(instance)
  client = FHIR::Client.new(instance.url)
  client.use_dstu2
  client.default_json
  client
end

def set_resource_support(instance, resource)
  interactions = ['read', 'search-type', 'history-instance', 'vread'].map do |interaction|
    {
      code: interaction
    }
  end
  Inferno::Models::ServerCapabilities.create(
    testing_instance_id: instance.id,
    capabilities: {
      rest: [
        {
          resource: [
            {
              type: resource.to_s,
              interaction: interactions
            }
          ]
        }
      ]
    }
  )
end

FHIR::DSTU2::StructureDefinition.clear_all_validates_vs
