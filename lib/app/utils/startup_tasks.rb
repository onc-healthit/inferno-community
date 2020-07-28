# frozen_string_literal: true

module Inferno
  module StartupTasks
    class << self
      def run
        load_all_modules
      end

      def load_all_modules
        Dir.glob(File.join(__dir__, '..', '..', 'modules', '*_module.yml')).each do |file|
          this_module = YAML.load_file(file).deep_symbolize_keys
          Module.new(this_module)
        end
      end
    end
  end
end
