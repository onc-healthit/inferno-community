# frozen_string_literal: true

require 'ast'
require 'parser/current'
require 'pry'
require_relative '../../lib/app/utils/assertions'

# To generate a sequence coverage report, run the unit tests with the
# ASSERTION_REPORT environment variable set to true:
#
# ASSERTION_REPORT=true bundle exec rake

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
    @stripped_file_name ||= file_name.split('lib/app/').last
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
      @assertion_locations ||= Set.new
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

    def add_assertion_call(result)
      location = AssertionCallLocationFormatter.new.location
      return if location.blank?

      add_assertion_location(location)
      assertion_calls[location] << result
    end
  end
end

class AssertionCallLocationFormatter
  SEQUENCE_LINE_REGEX = %r{inferno/lib/app/(modules/\w+/\w+\.rb:\d+)}.freeze
  LINE_REGEX = %r{inferno/lib/app/((?:\w+/?)+\.rb:\d+)}.freeze
  ASSERTION_CALL_REGEX = %r{inferno/lib/app/utils/assertions.rb:\d+}.freeze
  CALL_SEPARATOR = ' => '

  attr_accessor :sequence_call_index, :assertion_call_index

  def initialize
    generate_assertion_call_index
    generate_sequence_call_index
  end

  def backtrace
    @backtrace ||= caller_locations
  end

  def generate_sequence_call_index
    self.sequence_call_index = backtrace.rindex { |location| location.to_s.match? SEQUENCE_LINE_REGEX }

    adjust_index_to_handle_blocks
  end

  def generate_assertion_call_index
    self.assertion_call_index = backtrace.rindex { |location| location.to_s.match? ASSERTION_CALL_REGEX }
  end

  def method_name
    @method_name ||= backtrace[sequence_call_index].to_s.match(/`(.*)'/)&.[](1)
  end

  # This adjusts sequence_call_index so that when assertions are wrapped in a
  # warning block, this index refers to the method call inside the warning block
  # rather than the warning call itself
  def adjust_index_to_handle_blocks
    return if sequence_call_index.blank? || assertion_call_index.blank?

    (assertion_call_index...sequence_call_index).to_a.reverse.each do |index|
      self.sequence_call_index = index if backtrace[index].to_s.match?(/block .*in #{method_name}/)
    end
  end

  def location
    return unless sequence_call_index.present? && assertion_call_index.present?

    [backtrace[sequence_call_index], backtrace[assertion_call_index + 1]]
      .uniq
      .map { |location| location&.to_s&.match(LINE_REGEX)&.[](1) }
      .join(CALL_SEPARATOR)
  end
end

# This class generates a csv file with information on how many times each
# assertion passed or failed in unit tests. The output differentiates direct and
# indirect assertion calls. Direct assertion calls are assertions that are
# called directly in a test or method being tested. Indirect assertion calls are
# assertions that are called within a method that is called by the test being
# tested.
#
# test '1' do
#   assert true # direct assertion call
# end
#
# test '2' do
#   validate
# end
#
# def validate
#   assert true # Direct assertion call if we are unit testing the validate
#               # method.
#               # Indirect assertion call if we are unit testing test '2'.
# end
class AssertionReporter
  class << self
    def report
      create_csv
    end

    def create_csv
      CSV.open(File.join(__dir__, '..', '..', 'sequence_coverage.csv'), 'wb') do |csv|
        csv << [
          'Assertion Location',
          'Direct Pass Count',
          'Direct Fail Count',
          'Indirect Pass Count',
          'Indirect Fail Count'
        ]
        AssertionTracker.assertion_locations.sort.each do |location|
          csv << [
            location,
            direct_pass_count(location),
            direct_fail_count(location),
            indirect_pass_count(location),
            indirect_fail_count(location)
          ]
        end
      end
    end

    def direct_call?(location)
      location.include? AssertionCallLocationFormatter::CALL_SEPARATOR
    end

    def direct_pass_count(location)
      AssertionTracker.assertion_calls[location].count { |result| result }
    end

    def direct_fail_count(location)
      AssertionTracker.assertion_calls[location].count(&:!)
    end

    def indirect_pass_count(location)
      return if direct_call? location

      AssertionTracker.assertion_calls.reduce(0) do |count, (key, results)|
        key.end_with?(location) && key != location ? count + results.count { |result| result } : count
      end
    end

    def indirect_fail_count(location)
      return if direct_call? location

      AssertionTracker.assertion_calls.reduce(0) do |count, (key, results)|
        key.end_with?(location) && key != location ? count + results.count(&:!) : count
      end
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
