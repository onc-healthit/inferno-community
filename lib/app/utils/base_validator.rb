# frozen_string_literal: true

module Inferno
  # A base/abstract class for defining validator functionality.
  # This way we can eventually add multiple validators and let the user choose.
  class BaseValidator
    def initialize; end

    def validate(resource, fhir_version, profile=nil); end
  end
end
