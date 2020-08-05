# frozen_string_literal: true

module Inferno
  module Models
    class SequenceRequirement
      include DataMapper::Resource
      property :id, String, key: true, default: proc { SecureRandom.uuid }
      property :name, String, unique_index: :name_by_instance
      property :testing_instance_id, String, unique_index: :name_by_instance
      property :value, String
      property :label, String
      property :description, String

      belongs_to :testing_instance
    end
  end
end
