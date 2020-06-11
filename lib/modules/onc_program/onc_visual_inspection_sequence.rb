# frozen_string_literal: true

module Inferno
  module Sequence
    class ONCVisualInspectionSequence < SequenceBase
      title 'Visual Inspection and Attestation'
      description 'Verify conformance to portions of the test procedure that are not automated.'

      test_id_prefix 'ATT'

      requires :onc_visual_single_registration,
               :onc_visual_single_registration_notes,
               :onc_visual_multi_registration,
               :onc_visual_multi_registration_notes,
               :onc_visual_single_scopes,
               :onc_visual_single_scopes_notes,
               :onc_visual_single_offline_access,
               :onc_visual_single_offline_access_notes,
               :onc_visual_refresh_timeout,
               :onc_visual_refresh_timeout_notes,
               :onc_visual_introspection,
               :onc_visual_introspection_notes,
               :onc_visual_data_without_omission,
               :onc_visual_data_without_omission_notes,
               :onc_visual_multi_scopes_no_greater,
               :onc_visual_multi_scopes_no_greater_notes,
               :onc_visual_documentation,
               :onc_visual_documentation_notes

      test 'Health IT Module demonstrated support for application registration for single patients.' do
        metadata do
          id '01'
          link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'
          description %(
            Health IT Module demonstrated support for application registration for single patients.
          )
        end

        assert @instance.onc_visual_single_registration == 'true', 'Health IT Module did not demonstrate support for application registration for single patients.'
        pass @instance.onc_visual_single_registration_notes if @instance.onc_visual_single_registration_notes.present?
      end

      test 'Health IT Module demonstrated support for application registration for multiple patients.' do
        metadata do
          id '02'
          link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'
          description %(
            Health IT Module demonstrated support for supports application registration for multiple patients.
          )
        end

        assert @instance.onc_visual_multi_registration == 'true', 'Health IT Module did not demonstrate support for application registration for multiple patients.'
        pass @instance.onc_visual_multi_registration_notes if @instance.onc_visual_multi_registration_notes.present?
      end

      test 'Health IT Module demonstrated a graphical user interface for user to authorize FHIR resources.' do
        metadata do
          id '03'
          link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'
          description %(
            Health IT Module demonstrated a graphical user interface for user to authorize FHIR resources
          )
        end

        assert @instance.onc_visual_single_scopes == 'true', 'Health IT Module did not demonstrate a graphical user interface for user to authorize FHIR resources'
        pass @instance.onc_visual_single_scopes_notes if @instance.onc_visual_single_scopes_notes.present?
      end

      test 'Health IT Module demonstrated a graphical user interface to authorize offline access.' do
        metadata do
          id '04'
          link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'
          description %(
            Health IT Module demonstrated a graphical user interface for user to authorize offline access.
          )
        end

        assert @instance.onc_visual_single_offline_access == 'true', 'Health IT Module did not demonstrate a graphical user interface for user to authorize offline access'
        pass @instance.onc_visual_single_offline_access_notes if @instance.onc_visual_single_offline_access_notes.present?
      end

      test 'Health IT Module attested that refresh tokens had three month timeout period.' do
        metadata do
          id '05'
          link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'
          description %(
            Health IT Module attested that refresh tokens had three month timeout period.
          )
        end

        assert @instance.onc_visual_refresh_timeout == 'true', 'Health IT Module did attest that refresh tokens have three month timeout period'
        pass @instance.onc_visual_refresh_timeout_notes if @instance.onc_visual_refresh_timeout_notes.present?
      end

      test 'Health IT developer demonstrated the ability of the Health IT Module / authorization server to validate token it has issued.' do
        metadata do
          id '06'
          link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'
          description %(
            Health IT developer demonstrated the ability of the Health IT Module / authorization server to validate token it has issued
          )
        end

        assert @instance.onc_visual_introspection == 'true', 'Health IT Module did not demonstrate the ability of the Health IT Module / authorization server to validate token it has issued'
        pass @instance.onc_visual_introspection_notes if @instance.onc_visual_introspection_notes.present?
      end

      test 'Tester verifies that all information is accurate and without omission.' do
        metadata do
          id '07'
          link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'
          description %(
            Tester verifies that all information is accurate and without omission.
          )
        end

        assert @instance.onc_visual_data_without_omission == 'true', 'Tester did not verify that all information is accurate and without omission.'
        pass @instance.onc_visual_data_without_omission_notes if @instance.onc_visual_data_without_omission_notes.present?
      end

      test 'Information returned no greater than scopes pre-authorized for multi-patient queries.' do
        metadata do
          id '08'
          link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'
          description %(
            Information returned no greater than scopes pre-authorized for multi-patient queries.
          )
        end

        assert @instance.onc_visual_multi_scopes_no_greater == 'true', 'Tester did not verify that all information is accurate and without omission.'
        pass @instance.onc_visual_multi_scopes_no_greater_notes if @instance.onc_visual_multi_scopes_no_greater_notes.present?
      end

      test 'Health IT developer demonstrated the documentation is available at a publicly accessible URL.' do
        metadata do
          id '09'
          link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'
          description %(
            Health IT developer demonstrated the documentation is available at a publicly accessible URL.
          )
        end

        assert @instance.onc_visual_documentation == 'true', 'Health IT developer did not demonstrate the documentation is available at a publicly accessible URL.'
        pass @instance.onc_visual_documentation_notes if @instance.onc_visual_documentation_notes.present?
      end

      test 'Health IT developer confirms support for the PractitionerRole and RelatedPerson resources to fulfill must support requirements of referenced elements within US Core profiles.' do
        metadata do
          id '10'
          link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'
          description %(
            Health IT developer confirms support for the PractitionerRole and RelatedPerson resources to fulfill must support requirements of referenced elements within US Core profiles.
          )
        end

        assert @instance.onc_visual_other_resources == 'true', 'Health IT developer did not confirm support for the PractitionerRole and RelatedPerson resources.'
        pass @instance.onc_visual_other_resources_notes if @instance.onc_visual_other_resources_notes.present?
      end

      test 'The health IT developer confirms the Health IT module does not cache the JWK Set received via a TLS-protected URL for longer than the cache-control header received by an application indicates.' do
        metadata do
          id '11'
          link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'
          description %(
            The health IT developer confirms the Health IT module does not cache the JWK Set received via a TLS-protected URL for longer than the cache-control header indicates.
          )
        end

        assert @instance.onc_visual_jwks_cache == 'true', 'Health IT developer did not confirm that the JWK Sets are not cached for longer than appropriate.'
        pass @instance.onc_visual_jwks_cache_notes if @instance.onc_visual_jwks_cache_notes.present?
      end
    end
  end
end
