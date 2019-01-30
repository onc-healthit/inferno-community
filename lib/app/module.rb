require 'yaml'

module Inferno
  class Module

    @@modules = {}

    class TestSet

      attr_accessor :id
      attr_accessor :view
      attr_accessor :groups

      def initialize(id, view)
        @id = id
        @view = view
        @groups = []
      end
      
      def sequences
        @groups.map{|group| group.test_cases.map{|tc| tc.sequence}}.flatten
      end

      def test_cases
        @groups.map{|group| group.test_cases}.flatten
      end

      def test_case_by_id(test_case_id)
        test_cases.find {|tc| tc.id == test_case_id}
      end

      def variable_required_by(variable)
        sequences.select{ |sequence| sequence.requires.include? variable}
      end
  
      def variable_defined_by(variable)
        sequences.select{ |sequence| sequence.defines.include? variable}
      end

    end

    class TestGroup

      attr_accessor :test_set
      attr_accessor :name
      attr_accessor :overview
      attr_accessor :input_instructions
      attr_accessor :lock_variables
      attr_accessor :id
      attr_accessor :test_cases
      attr_accessor :run_all

      def initialize(test_set, name, overview, input_instructions, lock_variables, run_all)
        @test_set = test_set
        @name = name
        @id = name.gsub(/[^0-9a-z]/i, '')
        @overview = overview
        @run_all = run_all
        @test_cases = []
        @test_case_names = {}
        @input_instructions = input_instructions
        @lock_variables = lock_variables || []
      end

      def add_test_case(sequence_name, parameters = {})

        current_name = "#{test_set.id}_#{@id}_#{sequence_name}"
        index = 1
        while @test_case_names.has_key?(current_name)
          index += 1
          current_name = "#{test_set.id}_#{@id}_#{sequence_name}_#{index}"
          raise 'Too many test cases using the same scenario' if index > 99
        end

        @test_case_names[current_name] = true

        sequence = Inferno::Sequence::SequenceBase.descendants.find {|seq| seq.sequence_name == sequence_name}

        new_test_case = TestCase.new(current_name, self, sequence, parameters)

        @test_cases << new_test_case

        new_test_case

      end

    end

    class TestCase
      attr_accessor :id
      attr_accessor :test_group
      attr_accessor :sequence
      attr_accessor :parameters
  
      def initialize(id, test_group, sequence, parameters)
        @id = id
        @sequence = sequence
        @test_group = test_group
        @parameters = parameters
      end
  
      def title
        if !@parameters[:title].nil?
          @parameters[:title]
        else
          sequence.title
        end
      end
  
      def description
        if !@parameters[:description].nil?
          @parameters[:description]
        else
          sequence.description
        end
      end
    end 

    attr_accessor :name
    attr_accessor :title
    attr_accessor :hide_optional
    attr_accessor :description
    attr_accessor :default_test_set
    attr_accessor :fhir_version
    attr_accessor :test_sets

    def initialize(name, description, default_test_set, fhir_version, title)
      @name = name
      @description = description
      @default_test_set = default_test_set
      @fhir_version = fhir_version
      @test_sets = {}
      @title = title
      @hide_optional = hide_optional
    end

    def sequences
      @test_sets.values.map{|test_set| test_set.groups.map{|group| group.test_cases.map{|tc| tc.sequence}}}.flatten
    end
    
    def view_by_test_set(test_set)
      @test_sets[test_set.to_sym].view.to_sym
    end

    def sequence_by_name(sequence_name)
      sequences.find{|seq| seq.sequence_name == sequence_name}
    end

    def variable_required_by(variable)
      sequences.select{ |sequence| sequence.requires.include? variable}
    end

    def variable_defined_by(variable)
      sequences.select{ |sequence| sequence.defines.include? variable}
    end

    def self.get(inferno_module)
      @@modules[inferno_module]
    end

    def self.available_modules
      @@modules
    end

    def self.load_module(module_hash)

      new_module = self.new(module_hash[:name], module_hash[:description], module_hash[:default_test_set], module_hash[:fhir_version], module_hash[:title] || module_hash[:name])

      module_hash[:test_sets].each do |test_set_key, test_set|
        new_module.default_test_set = test_set_key.to_s if new_module.default_test_set.nil?
        new_test_set = TestSet.new(test_set_key, test_set[:view])
        all_groups = test_set[:tests].each do |group|
          new_group = TestGroup.new(new_test_set, group[:name], group[:overview], group[:input_instructions], group[:lock_variables], group[:run_all] || false)

          group[:sequences].each do |sequence|
            test_case = nil
            if sequence.instance_of?(String)
              test_case = new_group.add_test_case(sequence)
            else
              test_case = new_group.add_test_case(sequence[:sequence], sequence)
            end
    
          end

          new_test_set.groups << new_group

        end
        
        
        new_module.test_sets[test_set_key] = new_test_set

      end

      @@modules[module_hash[:name]] = new_module

    end

    Dir.glob(File.join(__dir__, 'modules', '*_module.yml')).each do |file|
      this_module = YAML.load_file(file).deep_symbolize_keys
      self.load_module(this_module)
    end


  end
end
