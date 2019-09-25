module Inferno
  module Sequence
    class InfernoTest
      attr_reader :sequence, :test_block

      def initialize(sequence, &test_block)
        @sequence = sequence
        @test_block = test_block
        load_metadata
      end

      def metadata
        yield
        raise MetadataException
      end

      def load_metadata
        begin
          instance_eval(&test_block)
        rescue MetadataException
        end
      end

      def id(id = nil)
        @id ||= id
      end

      def link(link = nil)
        @link ||= link
      end

      def optional
        @optional ||= true
      end

      def desc(description = nil)
        @description ||= description
      end

      def versions(*versions)
        @versions ||= versions
      end
    end
  end
end
