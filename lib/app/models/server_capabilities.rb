# frozen_string_literal: true

require 'dm-types'

module Inferno
  module Models
    class ServerCapabilities
      include DataMapper::Resource
      property :id, String, key: true, default: proc { SecureRandom.uuid }
      property :capabilities, Json, lazy: false # lazy loading Json properties is broken

      belongs_to :testing_instance

      self.raise_on_save_failure = true

      def supported_resources
        statement.rest.each_with_object(Set.new) do |rest, resources|
          rest.resource.each { |resource| resources << resource.type }
        end
      end

      private

      def statement
        @statement ||= FHIR::CapabilityStatement.new(capabilities)
      end
    end
  end
end
