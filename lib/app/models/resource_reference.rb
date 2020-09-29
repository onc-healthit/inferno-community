# frozen_string_literal: true

module Inferno
  class ResourceReference < ApplicationRecord
    attribute :id, :string, default: -> { SecureRandom.uuid }
    attribute :resource_id, :string

    belongs_to :testing_instance
  end
end
