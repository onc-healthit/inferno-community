require 'ast'
require 'parser/current'
require 'pry'
require_relative './lib/app/utils/assertions'

# AST processor to find the location of each assertion in a sequence
class SequenceProcessor
  include AST::Processor::Mixin

  attr_reader :file_name

  def initialize(file_name)
    @file_name = file_name
  end

  def handler_missing(node)
    node.children.each { |child| process(child) if child.respond_to? :to_ast }
  end

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

# Store the location of each assertion in a sequence
class AssertionTracker
  class << self
    def assertion_method_names
      @assertion_method_names ||= Set.new(Inferno::Assertions.instance_methods)
    end

    def assertion_locations
      @assertion_locations ||= []
    end

    def assertion?(method_name)
      assertion_method_names.include? method_name
    end

    def add_assertion_location(location)
      assertion_locations << location
    end
  end
end

sequence_paths = File.join(__dir__, 'lib', 'app', 'modules', '*', '*.rb')

Dir.glob(sequence_paths).sort.each do |sequence_file_name|
  file_contents = File.read(sequence_file_name)
  ast = Parser::CurrentRuby.parse(file_contents)

  processor = SequenceProcessor.new(sequence_file_name)
  processor.process(ast)
end

puts AssertionTracker.assertion_locations
