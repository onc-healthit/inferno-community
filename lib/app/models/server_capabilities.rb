# frozen_string_literal: true

module Inferno
  class ServerCapabilities < ApplicationRecord
    attribute :id, :string, default: -> { SecureRandom.uuid }
    serialize :capabilities, JSON

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
            interactions: resource_interactions(resource).sort,
            operations: resource_operations(resource).sort
          }
        end
      end
    end

    def supported_profiles
      profile_urls = statement.rest.flat_map(&:resource)
        &.flat_map { |resource| resource.supportedProfile + [resource.profile] }
        &.compact || []
      profile_urls.map { |profile_url| profile_url.split('|').first }
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

    def search_documented?(resource_type)
      statement&.rest&.any? do |rest|
        rest&.resource
          &.select { |resource| resource&.type == resource_type }
          &.flat_map(&:interaction)
          &.select { |interaction| interaction&.code == 'search-type' }
          &.any? { |interaction| interaction&.documentation&.present? }
      end
    end

    def supported_search_params(resource_type)
      rest_resource(resource_type)&.searchParam&.map(&:name) || []
    end

    def supported_includes(resource_type)
      rest_resource(resource_type)&.searchInclude || []
    end

    def include_supported?(resource_type, include)
      supported_includes(resource_type).include?('*') ||
        supported_includes(resource_type).include?(include)
    end

    def supported_revincludes(resource_type)
      rest_resource(resource_type)&.searchRevInclude || []
    end

    def revinclude_supported?(resource_type, revinclude)
      supported_revincludes(resource_type).include?('*') ||
        supported_revincludes(resource_type).include?(revinclude)
    end

    private

    def statement
      @statement ||= FHIR::CapabilityStatement.new(capabilities)
    end

    def rest_resource(resource_type)
      statement&.rest&.first&.resource
        &.find { |resource| resource&.type == resource_type }
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

    def resource_operations(resource)
      resource.operation.map(&:name)
    end
  end
end
