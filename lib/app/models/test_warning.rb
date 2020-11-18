# frozen_string_literal: true

module Inferno
  class TestWarning < ApplicationRecord
    attribute :id, :string, default: -> { SecureRandom.uuid }

    belongs_to :test_result
  end
end
