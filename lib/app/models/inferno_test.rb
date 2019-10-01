# frozen_string_literal: true

module Inferno
  module Sequence
    class InfernoTest
      attr_reader :name, :index, :id_prefix, :test_block

      def initialize(name, index, id_prefix, &test_block)
        @name = name
        @index = index
        @id_prefix = id_prefix
        @test_block = test_block
        load_metadata
      end

      def id(id = nil)
        return @id if id.blank?

        @id = "#{id_prefix}-#{id}"
      end

      def link(link = nil)
        @link ||= link
      end

      def ref(ref = nil)
        @ref ||= ref
      end

      def optional
        @optional = true
      end

      def optional?
        @optional
      end

      def required?
        !optional?
      end

      def description(description = nil)
        @description ||= description
      end

      def desc(desc = nil)
        Inferno.logger.warn "'desc' has been deprecated. Use 'description' instead. Called from #{caller.first}"
        description(desc)
      end

      def versions(*versions)
        @versions ||= versions
      end

      def metadata_hash
        {
          test_id: id,
          name: name,
          description: description,
          required: required?,
          url: link,
          ref: ref
        }
      end

      private

      def metadata
        yield
        raise MetadataException # Prevent the rest of the test from running
      end

      def load_metadata
        instance_eval(&test_block)
      rescue MetadataException # rubocop:disable Lint/HandleExceptions
      end
    end
  end
end
