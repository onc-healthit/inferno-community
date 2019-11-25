# frozen_string_literal: true

module Inferno
  class Module
    class Tag
      attr_accessor :name
      attr_accessor :description
      attr_accessor :url

      def initialize(name, description, url)
        @name = name
        @description = description
        @url = url
      end
    end
  end
end
