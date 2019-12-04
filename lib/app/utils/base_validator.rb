# frozen_string_literal: true

module Inferno
  # A base/abstract class for defining validator functionality.
  class BaseValidator
    def validate(resource, fhir_version, profile = nil); end
  end
end
