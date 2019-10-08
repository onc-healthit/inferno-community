# frozen_string_literal: true

module Inferno
  module Sequence
    class BlueButtonExplanationOfBenefitSequence < SequenceBase
      group 'BlueButton 2.0 Profile Conformance'

      title 'ExplanationOfBenefit'

      description 'Verify that ExplanationOfBenefit resources on the FHIR server conform to the BlueButton 2.0 Implementation Guide'

      test_id_prefix 'BBEB'

      requires :token, :patient_id

      def validate_resource_item(resource, property, value)
        case property
        when 'patient'
          assert (resource.patient&.reference&.include?(value)), 'Patient on resource does not match patient requested'
        end
      end

      test 'Server rejects ExplanationOfBenefit search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
          )
          versions :stu3
        end

        skip_if_not_supported(:ExplanationOfBenefit, [:search, :read])

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('ExplanationOfBenefit'), patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from ExplanationOfBenefit search by patient' do
        metadata do
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
          )
          versions :stu3
        end

        skip_if_not_supported(:ExplanationOfBenefit, [:search, :read])

        search_params = { patient: @instance.patient_id }
        reply = get_resource_by_params(versioned_resource_class('ExplanationOfBenefit'), search_params)
        validate_search_reply(versioned_resource_class('ExplanationOfBenefit'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('ExplanationOfBenefit'), reply)
      end

      test 'ExplanationOfBenefit resources associated with Patient conform to BlueButton 2.0 Carrier profile' do
        metadata do
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-smokingstatus.html'
          description %(
          )
          versions :stu3
        end
        test_resources_against_profile('ExplanationOfBenefit', Inferno::ValidationUtil::BLUEBUTTON_URIS[:carrier])
        skip_unless @profiles_encountered.include?(Inferno::ValidationUtil::BLUEBUTTON_URIS[:carrier]), 'No Carrier ExplanationOfBenefits found.'
        assert !@profiles_failed.include?(Inferno::ValidationUtil::BLUEBUTTON_URIS[:carrier]), "Carrier ExplanationOfBenefits failed validation.<br/>#{@profiles_failed[Inferno::ValidationUtil::BLUEBUTTON_URIS[:carrier]]}"
      end

      test 'ExplanationOfBenefit resources associated with Patient conform to BlueButton 2.0 DME profile' do
        metadata do
          id '04'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-smokingstatus.html'
          description %(
          )
          versions :stu3
        end
        test_resources_against_profile('ExplanationOfBenefit', Inferno::ValidationUtil::BLUEBUTTON_URIS[:dme])
        skip_unless @profiles_encountered.include?(Inferno::ValidationUtil::BLUEBUTTON_URIS[:dme]), 'No DME ExplanationOfBenefits found.'
        assert !@profiles_failed.include?(Inferno::ValidationUtil::BLUEBUTTON_URIS[:dme]), "DME ExplanationOfBenefits failed validation.<br/>#{@profiles_failed[Inferno::ValidationUtil::BLUEBUTTON_URIS[:dme]]}"
      end

      test 'ExplanationOfBenefit resources associated with Patient conform to BlueButton 2.0 HHA profile' do
        metadata do
          id '05'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-smokingstatus.html'
          description %(
          )
          versions :stu3
        end
        test_resources_against_profile('ExplanationOfBenefit', Inferno::ValidationUtil::BLUEBUTTON_URIS[:hha])
        skip_unless @profiles_encountered.include?(Inferno::ValidationUtil::BLUEBUTTON_URIS[:hha]), 'No HHA ExplanationOfBenefits found.'
        assert !@profiles_failed.include?(Inferno::ValidationUtil::BLUEBUTTON_URIS[:hha]), "HHA ExplanationOfBenefits failed validation.<br/>#{@profiles_failed[Inferno::ValidationUtil::BLUEBUTTON_URIS[:hha]]}"
      end

      test 'ExplanationOfBenefit resources associated with Patient conform to BlueButton 2.0 Hospice profile' do
        metadata do
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-smokingstatus.html'
          description %(
          )
          versions :stu3
        end
        test_resources_against_profile('ExplanationOfBenefit', Inferno::ValidationUtil::BLUEBUTTON_URIS[:hospice])
        skip_unless @profiles_encountered.include?(Inferno::ValidationUtil::BLUEBUTTON_URIS[:hospice]), 'No Hospice ExplanationOfBenefits found.'
        assert !@profiles_failed.include?(Inferno::ValidationUtil::BLUEBUTTON_URIS[:hospice]), "Hospice ExplanationOfBenefits failed validation.<br/>#{@profiles_failed[Inferno::ValidationUtil::BLUEBUTTON_URIS[:hospice]]}"
      end

      test 'ExplanationOfBenefit resources associated with Patient conform to BlueButton 2.0 Inpatient profile' do
        metadata do
          id '07'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-smokingstatus.html'
          description %(
          )
          versions :stu3
        end
        test_resources_against_profile('ExplanationOfBenefit', Inferno::ValidationUtil::BLUEBUTTON_URIS[:inpatient])
        skip_unless @profiles_encountered.include?(Inferno::ValidationUtil::BLUEBUTTON_URIS[:inpatient]), 'No Inpatient ExplanationOfBenefits found.'
        assert !@profiles_failed.include?(Inferno::ValidationUtil::BLUEBUTTON_URIS[:inpatient]), "Inpatient ExplanationOfBenefits failed validation.<br/>#{@profiles_failed[Inferno::ValidationUtil::BLUEBUTTON_URIS[:inpatient]]}"
      end

      test 'ExplanationOfBenefit resources associated with Patient conform to BlueButton 2.0 Outpatient profile' do
        metadata do
          id '08'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-smokingstatus.html'
          description %(
          )
          versions :stu3
        end
        test_resources_against_profile('ExplanationOfBenefit', Inferno::ValidationUtil::BLUEBUTTON_URIS[:outpatient])
        skip_unless @profiles_encountered.include?(Inferno::ValidationUtil::BLUEBUTTON_URIS[:outpatient]), 'No Outpatient ExplanationOfBenefits found.'
        assert !@profiles_failed.include?(Inferno::ValidationUtil::BLUEBUTTON_URIS[:outpatient]), "Outpatient ExplanationOfBenefits failed validation.<br/>#{@profiles_failed[Inferno::ValidationUtil::BLUEBUTTON_URIS[:outpatient]]}"
      end

      test 'ExplanationOfBenefit resources associated with Patient conform to BlueButton 2.0 PDE profile' do
        metadata do
          id '09'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-smokingstatus.html'
          description %(
          )
          versions :stu3
        end
        test_resources_against_profile('ExplanationOfBenefit', Inferno::ValidationUtil::BLUEBUTTON_URIS[:pde])
        skip_unless @profiles_encountered.include?(Inferno::ValidationUtil::BLUEBUTTON_URIS[:pde]), 'No PDE ExplanationOfBenefits found.'
        assert !@profiles_failed.include?(Inferno::ValidationUtil::BLUEBUTTON_URIS[:pde]), "PDE ExplanationOfBenefits failed validation.<br/>#{@profiles_failed[Inferno::ValidationUtil::BLUEBUTTON_URIS[:pde]]}"
      end

      test 'ExplanationOfBenefit resources associated with Patient conform to BlueButton 2.0 SNF profile' do
        metadata do
          id '10'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-smokingstatus.html'
          description %(
          )
          versions :stu3
        end
        test_resources_against_profile('ExplanationOfBenefit', Inferno::ValidationUtil::BLUEBUTTON_URIS[:snf])
        skip_unless @profiles_encountered.include?(Inferno::ValidationUtil::BLUEBUTTON_URIS[:snf]), 'No SNF ExplanationOfBenefits found.'
        assert !@profiles_failed.include?(Inferno::ValidationUtil::BLUEBUTTON_URIS[:snf]), "SNF ExplanationOfBenefits failed validation.<br/>#{@profiles_failed[Inferno::ValidationUtil::BLUEBUTTON_URIS[:snf]]}"
      end
    end
  end
end
