# frozen_string_literal: true

module Inferno
  class SequenceRequirement < ApplicationRecord
    attribute :id, :string, default: -> { SecureRandom.uuid }

    belongs_to :testing_instance
  end
end
