# frozen_string_literal: true

module Inferno
  module IpsProfileDefinitions
    class IpsPatientuvipsSequenceDefinition
      PROFILE_URL = 'http://hl7.org/fhir/uv/ips/StructureDefinition/Patient-uv-ips'
      MUST_SUPPORTS = {
        extensions: [],
        slices: [],
        elements: [
          {
            path: 'Patient'
          },
          {
            path: 'identifier'
          },
          {
            path: 'name'
          },
          {
            path: 'name.text'
          },
          {
            path: 'name.family'
          },
          {
            path: 'name.given'
          },
          {
            path: 'telecom'
          },
          {
            path: 'gender'
          },
          {
            path: 'birthDate'
          },
          {
            path: 'address'
          },
          {
            path: 'contact'
          },
          {
            path: 'contact.relationship'
          },
          {
            path: 'contact.name'
          },
          {
            path: 'contact.telecom'
          },
          {
            path: 'contact.address'
          },
          {
            path: 'contact.organization'
          },
          {
            path: 'communication'
          },
          {
            path: 'communication.language'
          },
          {
            path: 'generalPractitioner'
          }
        ]
      }.freeze
      SEARCH_PARAMETERS = [].freeze
    end
  end
end
