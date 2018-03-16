require 'simplecov'
SimpleCov.start

ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'webmock/minitest'
require 'rack/test'

require File.expand_path '../../app.rb', __FILE__

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
