# frozen_string_literal: true

module Inferno
  module Models
    class TestWarning
      include DataMapper::Resource
      property :id, String, key: true, default: proc { SecureRandom.uuid }
      property :message, String, length: 500

      belongs_to :test_result
    end
  end
end
