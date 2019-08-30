# frozen_string_literal: true

require 'dm-types'

module Inferno
  module Models
    class ServerCapabilities
      include DataMapper::Resource
      property :id, String, key: true, default: proc { SecureRandom.uuid }
      property :capabilities, Json, lazy: false # lazy loading Json properties is broken

      belongs_to :testing_instance

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

      def operation_supported?(op_name)
        statement.rest.any? { |r| r.operation.any? { |x| x.name == op_name } }
      end

      private

      def statement
        @statement ||= FHIR::CapabilityStatement.new(capabilities)
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
