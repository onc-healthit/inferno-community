# frozen_string_literal: true

require 'yaml'

require_relative 'module/test_group'
require_relative 'module/test_set'
require_relative 'module/tag'

module Inferno
  class Module
    @modules = {}

    attr_accessor :default_test_set
    attr_accessor :description
    attr_accessor :fhir_version
    attr_accessor :hide_optional
    attr_accessor :name
    attr_accessor :tags
    attr_accessor :test_sets
    attr_accessor :title

    def initialize(params)
      @name = params[:name]
      @description = params[:description]
      @default_test_set = params[:default_test_set]
      @fhir_version = params[:fhir_version]
      @title = params[:title] || params[:name]
      @hide_optional = params[:hide_optional]
      @tags = params[:tags]&.map do |tag|
        Tag.new(tag[:name], tag[:description], tag[:url])
      end || []
      @test_sets = {}.tap do |test_sets|
        params[:test_sets].each do |test_set_key, test_set|
          self.default_test_set ||= test_set_key.to_s
          test_sets[test_set_key] = TestSet.new(test_set_key, test_set)
        end
      end

      Module.add(name, self)
    end

    def sequences
      test_sets.values.flat_map do |test_set|
        test_set.groups.flat_map { |group| group.test_cases.map(&:sequence) }
      end
    end

    def view_by_test_set(test_set)
      test_sets[test_set.to_sym].view.to_sym
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

    def resources_to_test
      @resources_to_test ||= Set.new(sequences.flat_map(&:resources_to_test))
    end

    def self.add(name, inferno_module)
      @modules[name] = inferno_module
    end

    def self.get(inferno_module)
      @modules[inferno_module]
    end

    def self.available_modules
      @modules
    end

    Dir.glob(File.join(__dir__, '..', '..', 'modules', '*_module.yml')).each do |file|
      this_module = YAML.load_file(file).deep_symbolize_keys
      new(this_module)
    end
  end
end
