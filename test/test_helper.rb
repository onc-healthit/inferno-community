require 'simplecov'
SimpleCov.start

ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'webmock/minitest'
require 'rack/test'
require 'json/jwt'

#require File.expand_path '../../app.rb', __FILE__
require_relative '../lib/app'

def load_json_fixture(file)
   JSON.parse(load_fixture(file))
end

def load_fixture(file)
   root = File.dirname(File.absolute_path(__FILE__))
   File.read(File.join(root, 'fixtures', "#{file.to_s}.json"))
end

def save_fixture(file_name, content)
   root = File.dirname(File.absolute_path(__FILE__))
   File.write(File.join(root, 'fixtures', file.to_s), content)
end

def valid_uri?(uri)
  !(uri =~ /\A#{URI::regexp(['http', 'https'])}\z/).nil?
end

def wrap_resources_in_bundle(resources, type: 'searchset')
  bundle = FHIR::DSTU2::Bundle.new('id': 'foo', 'type': type)
  resources  = [resources].flatten.compact
  resources.each do |resource|
    bundle.entry << FHIR::DSTU2::Bundle::Entry.new
    bundle.entry.last.resource = resource
  end
  bundle
end

def get_resources_from_bundle(bundle,resourceType)
  resources = []
  bundle.entry.each do |entry|
    resources << entry.resource if entry.resource.resourceType == resourceType
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
                      token: JSON::JWT.new({iss: 'foo'}))

  @instance = Inferno::Models::TestingInstance.new(url: url,
                                                   client_name: client_name,
                                                   base_url: base_url,
                                                   client_endpoint_key: client_endpoint_key,
                                                   client_id: client_id,
                                                   oauth_authorize_endpoint: oauth_authorize_endpoint,
                                                   oauth_token_endpoint: oauth_token_endpoint,
                                                   scopes: scopes,
                                                   selected_module: 'argonaut',
                                                   token: token)
end

def get_client(instance)
  client = FHIR::Client.new(instance.url)
  client.use_dstu2
  client.default_json
  client
end

FHIR::DSTU2::StructureDefinition.clear_all_validates_vs()
