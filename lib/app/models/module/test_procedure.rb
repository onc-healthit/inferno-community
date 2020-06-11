# frozen_string_literal: true

module Inferno
  class Module
    class TestProcedure
      # procedure -> section -> steps
      attr_accessor :sections
      attr_accessor :inferno_module

      def initialize(data, inferno_module)
        @sections = data[:procedure].map { |section| Section.new(section, inferno_module) }
      end

      class Section
        attr_accessor :name
        attr_accessor :steps
        attr_accessor :inferno_module

        def initialize(data, inferno_module)
          @name = data[:section]
          @inferno_module = inferno_module

          group = nil
          @steps = data[:steps].map do |step|
            if step[:group].nil?
              step[:group] = group
            else
              group = step[:group]
            end

            Step.new(step, inferno_module)
          end
        end
      end

      class Step
        attr_accessor :inferno_module
        attr_accessor :group
        attr_accessor :id
        attr_accessor :s_u_t
        attr_accessor :t_l_v
        attr_accessor :inferno_supported
        attr_accessor :inferno_notes
        attr_accessor :inferno_tests
        attr_accessor :alternate_test

        def initialize(data, inferno_module)
          @group = data[:group]
          @id = data[:id]
          @s_u_t = data[:SUT]
          @t_l_v = data[:TLV]
          @inferno_supported = data[:inferno_supported]
          @inferno_notes = data[:inferno_notes]
          @alternate_test = data[:alternate_test]
          @inferno_module = inferno_module
          @inferno_tests = expand_tests(data[:inferno_tests]).flatten
        end

        def expand_tests(test_list)
          return [] if test_list.nil?

          test_list.map do |test|
            if test.include?(' - ')
              first, second = test.split(' - ')
              prefix, _, beginning = first.rpartition('-')
              second_prefix, _, ending = second.rpartition('-')
              raise "'#{prefix}' != '#{second_prefix}' in #{@group} #{@id}" unless prefix == second_prefix

              (beginning.to_i..ending.to_i).map { |index| prefix + '-' + format('%02<index>d', { index: index }) }
            else
              [test]
            end
          end
        end
      end
    end
  end
end
