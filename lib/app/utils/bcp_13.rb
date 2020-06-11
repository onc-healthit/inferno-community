# frozen_string_literal: true

module Inferno
  class Terminology
    module BCP13
      @code_set = nil

      def self.code_set
        @code_set ||= parse_code_set
      end

      def self.parse_code_set
        require 'mime/types'
        cs_set = Set.new
        MIME::Types.each do |type|
          cs_set.add(system: 'urn:ietf:bcp:13', code: type.simplified)
        end
        cs_set
      end
    end
  end
end
