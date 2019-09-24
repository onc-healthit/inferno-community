# frozen_string_literal: true

require 'dm-types'

module Inferno
  module Models
    class ServerCapabilities
      include DataMapper::Resource
      property :id, String, key: true, default: proc { SecureRandom.uuid }
      property :capabilities, Json, lazy: false # lazy loading Json properties is broken

      belongs_to :testing_instance

      SMART_EXTENSION_URL = 'http://fhir-registry.smarthealthit.org/StructureDefinition/capabilities'

      def supported_resources
        statement.rest.each_with_object(Set.new) do |rest, resources|
          rest.resource.each { |resource| resources << resource.type }
        end
      end

      def supported_interactions
        statement.rest.flat_map do |rest|
          rest.resource.map do |resource|
            {
              resource_type: resource.type,
              interactions: resource_interactions(resource).sort
            }
          end
        end
      end

      def operation_supported?(operation_name)
        statement.rest.any? { |rest| rest.operation.any? { |operation| operation.name == operation_name } }
      end

      def smart_support?
        smart_extensions.present?
      end

      def smart_capabilities
        smart_extensions.map(&:valueCode)
      end

      private

      def statement
        @statement ||= FHIR::CapabilityStatement.new(capabilities)
      end

      def security_extensions
        @security_extensions ||=
          statement&.rest&.flat_map { |rest| rest&.security&.extension }&.compact || []
      end

      def smart_extensions
        @smart_extensions ||=
          security_extensions.select { |extension| extension.url == SMART_EXTENSION_URL }
      end

      def interaction_display(interaction)
        if interaction.code == 'search-type'
          'search'
        else
          interaction.code
        end
      end

      def resource_interactions(resource)
        resource.interaction.map { |interaction| interaction_display(interaction) }
      end
    end
  end
end
