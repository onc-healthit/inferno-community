# frozen_string_literal: true

module Inferno
  class ApplicationRecord < ::ActiveRecord::Base
    self.abstract_class = true

    def self.table_name_prefix
      'inferno_models_'
    end
  end
end
