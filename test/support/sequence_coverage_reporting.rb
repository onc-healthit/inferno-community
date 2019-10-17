# frozen_string_literal: true

require 'ast'
require 'parser/current'
require 'pry'
require_relative '../../lib/app/utils/assertions'

# AST processor which finds the location of each assertion in a sequence
class SequenceProcessor
  include AST::Processor::Mixin

  attr_reader :file_name

  def initialize(file_name)
    @file_name = file_name
  end

  def handler_missing(node)
    node.children.each { |child| process(child) if child.respond_to? :to_ast }
  end

  # If an assertion is called, record its location
  def on_send(node)
    _, method_name = *node
    AssertionTracker.add_assertion_location(location(node)) if AssertionTracker.assertion? method_name
  end

  def location(node)
    "#{stripped_file_name}:#{node.loc.line}"
  end

  def stripped_file_name
    @stripped_file_name ||= file_name.split('lib/app/modules/').last
  end
end

# Store the location of each assertion in a sequence, and track each time an
# assertion is called
class AssertionTracker
  class << self
    def assertion_method_names
      @assertion_method_names ||= Set.new(Inferno::Assertions.instance_methods)
    end

    # Assertion locations determined through analyzing the AST
    def assertion_locations
      @assertion_locations ||= []
    end

    # Assertion calls detected at runtime
    def assertion_calls
      @assertion_calls ||= Hash.new { |hash, key| hash[key] = [] }
    end

    def assertion?(method_name)
      assertion_method_names.include? method_name
    end

    def add_assertion_location(location)
      assertion_locations << location
    end

    def add_assertion_call(location, result)
      assertion_calls[location] << result
    end
  end
end

class AssertionReporter
  class << self
    def report
      create_csv
      print_unknown_call_sites
    end

    def create_csv
      CSV.open(File.join(__dir__, '..', '..', 'sequence_coverage.csv'), 'wb') do |csv|
        csv << ['Assertion Location', 'Pass Count', 'Fail Count']
        AssertionTracker.assertion_locations.sort.each do |location|
          results = AssertionTracker.assertion_calls[location]
          csv << [location, pass_count(results), fail_count(results)]
        end
      end
    end

    def pass_count(results)
      results.count { |result| result }
    end

    def fail_count(results)
      results.count(&:!)
    end

    # Locations which called an assertion which was not detected in the AST.
    # This happens when a method from outside of the sequence makes an assertion
    # (e.g., a method from SequenceBase).
    def unknown_call_sites
      AssertionTracker.assertion_calls.keys - AssertionTracker.assertion_locations
    end

    def print_unknown_call_sites
      return if unknown_call_sites.blank?

      puts "\nUnrecognized assertion call sites:"
      puts unknown_call_sites.join("\n")
    end
  end
end

sequence_paths = File.join(__dir__, '..', '..', 'lib', 'app', 'modules', '*', '*.rb')

Dir.glob(sequence_paths).sort.each do |sequence_file_name|
  file_contents = File.read(sequence_file_name)
  ast = Parser::CurrentRuby.parse(file_contents)

  processor = SequenceProcessor.new(sequence_file_name)
  processor.process(ast)
end
