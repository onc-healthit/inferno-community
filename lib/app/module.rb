require 'yaml'

module Inferno
  class Module

    @@modules = {}

    class Group

      attr_accessor :name
      attr_accessor :overview
      attr_accessor :sequences
      attr_accessor :run_all

      def initialize(config)
        @name = config[:name]
        @overview = config[:overview]
        @run_all = config[:run_all]

        @sequences = config[:sequences].map do |seq_string|
          Inferno::Sequence::SequenceBase.descendants.find {|seq| seq.sequence_name == seq_string}
        end
      end

    end

    attr_accessor :name
    attr_accessor :description
    attr_accessor :groups

    def initialize(config)
      @name = config[:name]
      @description = config[:name]
      @groups = config[:groups].map {|group| Group.new(group)}
    end

    def sequences
      groups.map{|h| h.sequences}.flatten
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

    Dir.glob(File.join(__dir__, 'sequences', '*_module.yml')).each do |file|
      this_module = YAML.load_file(file).deep_symbolize_keys
      @@modules[this_module[:name]] = self.new(this_module)
    end

  end
end
