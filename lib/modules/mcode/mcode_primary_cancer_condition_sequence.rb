# frozen_string_literal: true

module Inferno
  module Sequence
    class PrimaryCancerConditionSequence < SequenceBase
		title 'PrimaryCancerCondition Tests'

		description 'Verify that Condition resources on the FHIR server follow the mCode Implementation Guide'

		test_id_prefix 'PCC'

		requires :token, :patient_id
		conformance_supports :Condition

		  def validate_resource_item(resource, property, value)
	        case property

	        when 'patient'
	          value_found = can_resolve_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
	          assert value_found, 'patient on resource does not match patient requested'

	        when 'type'
	          value_found = can_resolve_path(resource, 'type.coding.code') { |value_in_resource| value_in_resource == value }
	          assert value_found, 'type on resource does not match type requested'

	        end
	      end

		  details %(
			The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
		  )

		  @resources_found = false

		  

		  test :unauthorized_search do
			metadata do
			  id '01'
			  name 'Server rejects Primary Cancer Condition search without authorization'
			  #link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
			  link 'http://build.fhir.org/ig/HL7/fhir-mCODE-ig/branches/master/StructureDefinition-onco-core-PrimaryCancerCondition.html'
			  description %(
				A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
			  )
			  versions :r4
			end

			#skip_if_not_supported(:PrimaryCancerCondition, [:search])

			@client.set_no_auth
			omit 'Do not test if no bearer token set' if @instance.token.blank?

			search_params = {
			  'patient': @instance.patient_id
			}

			reply = get_resource_by_params('PrimaryCancerCondition', search_params)
			@client.set_bearer_token(@instance.token)
			assert_response_unauthorized reply
		  end

		  test 'Server returns expected results from Condition search by patient' do
	        metadata do
	          id '02'
	          link 'http://build.fhir.org/ig/HL7/fhir-mCODE-ig/branches/master/StructureDefinition-onco-core-PrimaryCancerCondition.html'
	          description %(

	            A server SHALL support searching by patient on the Condition resource

	          )
	          versions :r4
	        end

	        #need to dynamically determine this profile based on inputed endpoint
	        profile = "https://api.logicahealth.org/mCODEstu1/StructureDefinition/onco-core-PrimaryCancerCondition"

	        search_params = {
	          'patient': @instance.patient_id,
	          '_profile': profile
	        }

	        

	        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
	        assert_response_ok(reply)
	        assert_bundle_response(reply)

	        resource_count = reply&.resource&.entry&.length || 0
	        @resources_found = true if resource_count.positive?

	        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

	        @condition = reply&.resource&.entry&.first&.resource
	        @condition_ary = fetch_all_bundled_resources(reply&.resource)
	        save_resource_ids_in_bundle(versioned_resource_class('Condition'), reply)
	        save_delayed_sequence_references(@condition_ary)
	        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)
          end

          test 'Server returns expected results from Condition by id' do
	        metadata do
	          id '03'
	          link 'http://build.fhir.org/ig/HL7/fhir-mCODE-ig/branches/master/StructureDefinition-onco-core-PrimaryCancerCondition.html'
	          description %(

	            A server SHALL support reading a Condition resource by id

	          )
	          versions :r4
	        end

	        condition_id = @condition.id 
	        fetch_resource('Condition', condition_id)
	        
          end

          test 'Condition resources associated with Condition conform to mCode profiles' do
	        metadata do
	          id '04'
	          link 'https://api.logicahealth.org/mCODEstu1/StructureDefinition/onco-core-PrimaryCancerCondition'
	          description %(

	            This test checks if the resources returned from prior searches conform to the US Core profiles.
	            This includes checking for missing data elements and valueset verification.

	          )
	          versions :r4
	        end

	        puts '-----------------------------------------------------------'

	        profile = "http://hl7.org/fhir/us/mcode/StructureDefinition/onco-core-PrimaryCancerCondition"

	        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
	        test_resources_against_profile('Condition', profile)

	        puts '-----------------------------------------------------------'

	      end


          
		end
	  end
	end

