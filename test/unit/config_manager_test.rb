# frozen_string_literal: true

require_relative '../test_helper'
require 'pathname'

describe Inferno::ConfigManager do
  before do
    @config_manager = Inferno::ConfigManager.new('test/fixtures/test_config.yml')
  end
  it 'initializes with a default config' do
    config_manager = Inferno::ConfigManager.new('test/fixtures/test_config.yml')
    config = config_manager.config
    assert config['app_name'] = 'Inferno'
    assert config['modules'] = ['onc', 'smart', 'bdt', 'argonaut', 'uscore_v3.1.0']
    assert config['presets']['site_healthit_gov']['name'] = 'SITE DSTU2 FHIR Sandbox'
  end

  it 'initializes without a default config' do
    config_manager = Inferno::ConfigManager.new
    assert config_manager.config.nil?
  end

  it 'will add modules if they do not already exist' do
    refute_includes @config_manager.modules, 'foo'
    @config_manager.add_modules 'foo'
    assert_includes @config_manager.modules, 'foo'
    @config_manager.add_modules 'foo'
    assert @config_manager.modules.uniq.length == @config_manager.modules.length
  end

  it 'allows users to set an app_name' do
    assert @config_manager.app_name == 'Inferno'
    @config_manager.app_name = 'foo'
    assert @config_manager.app_name = 'foo'
  end

  it 'makes sure that certain values are boolean' do
    assert @config_manager.log_to_file == false
    @config_manager.log_to_file = 'true'
    assert @config_manager.log_to_file == true
    @config_manager.log_to_file = 'false'
    assert @config_manager.log_to_file == false
  end

  it 'will save the config to a file' do
    @config_manager.add_modules 'foo'
    refute File.exist? 'test_config.yml'
    @config_manager.write_to_file('test_config.yml')
    assert File.exist? 'test_config.yml'
    File.delete 'test_config.yml'
    refute File.exist? 'test_config.yml'
  end
end
