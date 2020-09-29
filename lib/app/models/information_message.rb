# frozen_string_literal: true

module Inferno
  class InformationMessage < ApplicationRecord
    attribute :id, :string, default: -> { SecureRandom.uuid }

    belongs_to :test_result
  end
end
