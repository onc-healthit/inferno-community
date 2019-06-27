# frozen_string_literal: true

module Inferno
  module Models
    class SupportedResource
      include DataMapper::Resource
      property :id, String, key: true, default: proc { SecureRandom.uuid }
      property :index, Integer
      property :resource_type, String
      property :supported, Boolean, default: false
      property :read_supported, Boolean, default: false
      property :vread_supported, Boolean, default: false
      property :history_supported, Boolean, default: false
      property :search_supported, Boolean, default: false
      property :scope_supported, Boolean, default: false

      belongs_to :testing_instance

      # Returns an array containing the supported interaction of the resource
      #
      # @return [Array<Symbol>, nil] the supported interactions
      #   Returns nil if resource is not supported
      def supported_interactions
        return nil unless supported

        interactions = []
        interactions << :read if read_supported
        interactions << :vread if vread_supported
        interactions << :search if search_supported
        interactions << :history if history_supported
        interactions << :authorized if scope_supported
        interactions
      end
    end
  end
end
