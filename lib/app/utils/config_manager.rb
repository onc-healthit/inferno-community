# frozen_string_literal: true

require 'yaml'
module Inferno
  class ConfigManager
    # define methods for which anything may be assigned
    ['app_name', 'base_path', 'bind', 'default_scopes', 'log_level', 'badge_text', 'resource_validator', 'external_resource_validator_url'].each do |attribute|
      define_method attribute.to_sym do
        config[attribute]
      end
      define_method "#{attribute}=".to_sym do |value|
        config[attribute] = value
      end
    end

    # Define methds which should always assign a boolean value
    ['purge_database_on_reload', 'disable_verify_peer', 'disable_tls_tests', 'log_to_file', 'logging_enabled', 'include_extras'].each do |attribute|
      define_method attribute.to_sym do
        config[attribute]
      end
      define_method "#{attribute}=".to_sym do |value|
        config[attribute] = value.to_s.downcase == 'true'
      end
    end

    attr_reader :config
    def initialize(initial_config = nil)
      @config = YAML.load_file(initial_config) unless initial_config.nil?
    end

    def modules
      config['modules']
    end

    def add_modules(modules)
      self.modules |= Array(modules)
    end

    def remove_modules(modules)
      self.modules -= modules
    end

    def presets
      config['presets']
    end

    def remove_preset(name)
      config['presets'].delete(name)
    end

    def add_preset(key, preset_values)
      config[key.to_s] = preset_values
    end

    def write_to_file(filename)
      File.open(filename, 'w+') { |f| f.write(config.to_yaml) }
    end

    private

    attr_writer :config

    def modules=(modules)
      config['modules'] = modules
    end
  end
end
