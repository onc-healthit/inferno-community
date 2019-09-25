module Inferno
  module Sequence
    class InfernoTest
      attr_reader :name, :index, :test_block

      def initialize(name, index, &test_block)
        @name = name
        @test_block = test_block
        @index = index
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
        @optional = true
      end

      def optional?
        @optional
      end

      def required?
        !optional?
      end

      def desc(description = nil)
        @description ||= description
      end

      def versions(*versions)
        @versions ||= versions
      end

      def metadata_hash
        {
          test_id: id,
          name: name,
          description: desc,
          required: required?,
          url: link
        }
      end
    end
  end
end
