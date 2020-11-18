# frozen_string_literal: true

require_relative 'bdt_base'

module Inferno
  module Sequence
    class BDTCapabilityStatementSequence < BDTBase
      title 'Metadata'

      description 'Verify the CapabilityStatement conforms to the SMART Bulk Data IG.'

      test_id_prefix 'CapabilityStatement'

      requires :bulk_url, :bulk_token_endpoint, :bulk_client_id, \
               :bulk_system_export_endpoint, :bulk_patient_export_endpoint, :bulk_group_export_endpoint, \
               :bulk_fastest_resource, :bulk_requires_auth, :bulk_since_param, :bulk_jwks_url_auth, :bulk_jwks_url_auth, \
               :bulk_private_key

      details %(
        Metadata
      )

      test 'CapabilityStatement the CapabilityStatement instantiates the bulk-data CapabilityStatement' do
        metadata do
          id '1'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            To declare conformance with this IG, a server should include the following URL in its own CapabilityStatement.instantiates:

[http://hl7.org/fhir/uv/bulkdata/CapabilityStatement/bulk-data](http://www.hl7.org/fhir/bulk-data/CapabilityStatement-bulk-data.html).

The CapabilityStatement should contain something like:
```json
"instantiates": [
    "http://hl7.org/fhir/uv/bulkdata/CapabilityStatement/bulk-data"
]
```
          )
          versions :r4
        end

        run_bdt('5.0.0')
      end
      test 'CapabilityStatement includes the token endpoint in the CapabilityStatement' do
        metadata do
          id '2'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            If a server requires SMART on FHIR authorization for access, its metadata **must** support automated discovery of OAuth2 endpoints by including a "complex" extension (that is, an extension with multiple components inside) on the `CapabilityStatement.rest.security` element. Any time a client sees this extension, it must be prepared to authorize using SMART's OAuth2-based protocol.
This test is expecting to find the in `CapabilityStatement` an entry like:
```
"rest": [
  {
    "mode": "server",
    "security": {
      "extension": [
        {
          "url": "http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris",
          "extension": [
            {
              "url": "token",
              "valueUri": "https://someserver.org/auth/token"
            }
          ]
        }
      ]
    }
  }
]
```
Having a CapabilityStatement is optional for bulk data servers, unless they are also FHIR servers (which they typically are). However, missing a CapabilityStatement will generate a warning here.
          )
          versions :r4
        end

        run_bdt('5.0.1')
      end
      test 'CapabilityStatement check if "export" operation is defined in the CapabilityStatement' do
        metadata do
          id '3'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            This test expects to find in the CapabilityStatement an entry like:
```
"rest": [
  {
    "operation": [
      {
        "name" : "export",
        "definition": "..."
      }
    ]
  }
]
```
          )
          versions :r4
        end

        run_bdt('5.0.2')
      end
      test 'CapabilityStatement check if "patient-export" operation is defined in the CapabilityStatement' do
        metadata do
          id '4'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            This test expects to find in the CapabilityStatement an entry like:
```
"rest": [
  {
    "resource": [
      {
        "type": "Patient",
        "operation": [
          {
            "name" : "patient-export",
            "definition": "..."
          }
        ]
      }
    ]
  }
]
```
          )
          versions :r4
        end

        run_bdt('5.0.3')
      end
      test 'CapabilityStatement check if "group-export" operation is defined in the CapabilityStatement' do
        metadata do
          id '5'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            This test expects to find in the CapabilityStatement an entry like:
```
"rest": [
  {
    "resource": [
      {
        "type": "Group",
        "operation": [
          {
            "name" : "group-export",
            "definition": "..."
          }
        ]
      }
    ]
  }
]
```
          )
          versions :r4
        end

        run_bdt('5.0.4')
      end
      test 'Well Known SMART Configuration includes token_endpoint definition' do
        metadata do
          id '1'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            This test verifies that the server provides a `/.well-known/smart-configuration` and that a `token_endpoint` property is declared within that file.
          )
          versions :r4
        end

        run_bdt('5.1.0')
      end
    end
  end
end
