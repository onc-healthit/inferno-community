# frozen_string_literal: true

require 'yaml'

require_relative 'module/test_group'
require_relative 'module/test_set'

module Inferno
  class Module
    @@modules = {}

    attr_accessor :default_test_set
    attr_accessor :description
    attr_accessor :fhir_version
    attr_accessor :hide_optional
    attr_accessor :name
    attr_accessor :resources
    attr_accessor :test_sets
    attr_accessor :title

    def initialize(**params)
      @name = params[:name]
      @description = params[:description]
      @default_test_set = params[:default_test_set]
      @fhir_version = params[:fhir_version]
      @test_sets = {}
      @title = params[:title] || params[:name]
      @hide_optional = params[:hide_optional]
      @resources = Set.new(params[:resources])
    end

    def sequences
      @test_sets.values.flat_map { |test_set| test_set.groups.flat_map { |group| group.test_cases.map(&:sequence) } }
    end

    def view_by_test_set(test_set)
      @test_sets[test_set.to_sym].view.to_sym
    end

    def sequence_by_name(sequence_name)
      sequences.find { |seq| seq.sequence_name == sequence_name }
    end

    def variable_required_by(variable)
      sequences.select { |sequence| sequence.requires.include? variable }
    end

    def variable_defined_by(variable)
      sequences.select { |sequence| sequence.defines.include? variable }
    end

    def self.get(inferno_module)
      @@modules[inferno_module]
    end

    def self.available_modules
      @@modules
    end

    def self.load_module(module_hash)
      new_module = new(module_hash)

      module_hash[:test_sets].each do |test_set_key, test_set|
        new_module.default_test_set ||= test_set_key.to_s
        new_test_set = TestSet.new(test_set_key, test_set[:view])
        test_set[:tests].each do |group|
          new_group = TestGroup.new(
            new_test_set,
            group[:name],
            group[:overview],
            group[:input_instructions],
            group[:lock_variables],
            group[:run_all] || false,
            group[:run_skipped] || false
          )

          group[:sequences].each do |sequence|
            if sequence.instance_of?(String)
              new_group.add_test_case(sequence)
            else
              new_group.add_test_case(sequence[:sequence], sequence)
            end
          end

          new_test_set.groups << new_group
        end

        new_module.test_sets[test_set_key] = new_test_set
      end

      @@modules[module_hash[:name]] = new_module
    end

    Dir.glob(File.join(__dir__, '..', 'modules', '*_module.yml')).each do |file|
      this_module = YAML.load_file(file).deep_symbolize_keys
      load_module(this_module)
    end
  end
end
