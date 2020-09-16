# frozen_string_literal: true

require 'json'

# Extension to FHIR::Model. Prepending this into FHIR::Model (done below)
# allows us to call super() on initialize when we overriding it,
# while also defining new methods and attributes
module InfernoFHIRModelExtensions
  # These need to be attr_writers so they can be written to from from_json/xml
  # And so they can be deserialized
  attr_writer :source_hash, :source_text

  def initialize(hash = {})
    super(hash)
    @source_hash = hash
  end

  def source_contents
    @source_text || JSON.generate(@source_hash)
  end
end

module FHIR
  class Model
    prepend ::InfernoFHIRModelExtensions
  end
end

# Extension to FHIR::Json. Prepending this into FHIR::Json (done below)
# allows us to call super() on from_json
module InfernoJson
  def from_json(json)
    resource = super(json)
    resource.source_text = json
    resource
  end
end

# Extension to FHIR::Xml. Prepending this into FHIR::Xml (done below)
# allows us to call super() on from_xml
module InfernoXml
  def from_xml(xml)
    resource = super(xml)
    resource.source_text = xml
    resource
  end
end

module FHIR
  module Json
    class << self
      prepend InfernoJson
    end
  end
end

module FHIR
  module Xml
    class << self
      prepend InfernoXml
    end
  end
end
