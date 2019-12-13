# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
end

ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'webmock/minitest'
require 'rack/test'
require 'json/jwt'

test_log_filename = File.join('tmp', 'test.log')
FileUtils.rm test_log_filename if File.exist? test_log_filename

require_relative '../lib/app'

def set_global_mocks
  measures_endpoint = Inferno::CQF_RULER + 'Measure'
  stub_request(:get, measures_endpoint)
    .with(
      headers: {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Content-Type' => 'application/json+fhir',
        'Host' => 'localhost:8080'
      }
    )
    .to_return(status: 200, body: '', headers: {})
end

def load_json_fixture(file)
  JSON.parse(load_fixture(file))
end

def load_fixture(file)
  root = File.dirname(File.absolute_path(__FILE__))
  File.read(File.join(root, 'fixtures', "#{file}.json"))
end

def save_fixture(_file_name, content)
  root = File.dirname(File.absolute_path(__FILE__))
  File.write(File.join(root, 'fixtures', file.to_s), content)
end

def valid_uri?(uri)
  !(uri =~ /\A#{URI.regexp(['http', 'https'])}\z/).nil?
end

def wrap_resources_in_bundle(resources, type: 'searchset')
  bundle = FHIR::DSTU2::Bundle.new('id': 'foo', 'type': type)
  resources = [resources].flatten.compact
  resources.each do |resource|
    bundle.entry << FHIR::DSTU2::Bundle::Entry.new
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
                      token: JSON::JWT.new(iss: 'foo'))

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
