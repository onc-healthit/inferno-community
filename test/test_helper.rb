# require 'simplecov'
# SimpleCov.start
# WebMock.disable_net_connect!(allow: %w{codeclimate.com})

ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'webmock/minitest'
require 'rack/test'

require File.expand_path '../../app.rb', __FILE__

def load_json_fixture(file)
   root = File.dirname(File.absolute_path(__FILE__))
   JSON.parse(File.read(File.join(root, 'fixtures', "#{file.to_s}.json")))
end

def save_fixture(file_name, content)
   root = File.dirname(File.absolute_path(__FILE__))
   File.write(File.join(root, 'fixtures', file.to_s), content)
end
