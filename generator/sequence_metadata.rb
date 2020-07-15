# frozen_string_literal: true

module Inferno
  module Generator
    class SequenceMetadata
      attr_reader :profile,
                  :tests
      attr_writer :class_name,
                  :file_name,
                  :requirements,
                  :sequence_name,
                  :test_id_prefix,
                  :title,
                  :url

      def initialize(profile)
        @profile = profile
        @tests = []
      end

      def resource_type
        profile['type']
      end

      def sequence_name
        @sequnce_name ||=
          profile['name']
            .split('-')
            .map(&:capitalize)
            .join
      end

      def class_name
        @class_name ||= sequence_name + 'Sequence'
      end

      def file_name
        @file_name ||= sequence_name.underscore + '_sequence'
      end

      def title
        @title ||= profile['title'] || profile['name']
      end

      def test_id_prefix
        # this needs to be made more generic
        @test_id_prefix ||= profile['name'].chars.select { |c| c.upcase == c && c != ' ' }.join
      end

      def requirements
        @requirements ||= [":#{resource_type.underscore}_id"]
      end

      def url
        @url ||= profile['url']
      end

      def add_test(test)
        @tests << test
      end

      def get_binding
        binding
      end
    end
  end
end
