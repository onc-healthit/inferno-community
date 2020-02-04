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


          #test 'Condition conforms to Primary Cancer Condition Profile' do
	      #  metadata do
	       #   id '04'
	       #   link 'http://build.fhir.org/ig/HL7/fhir-mCODE-ig/branches/master/StructureDefinition-onco-core-PrimaryCancerCondition.html'
	       #   description %(

	       #    Conditions should conform to the the Primary Cancer Condition profile

	       #   )
	       #   versions :r4
	       # end

	        # test that it conforms
	        
          #end




=begin
		  test 'Server returns expected results from PrimaryCancerCondition search by patient' do
			metadata do
			  id '02'
			  link 'http://build.fhir.org/ig/HL7/fhir-mCODE-ig/branches/master/StructureDefinition-onco-core-PrimaryCancerCondition.html'
			  description %(

				A server SHALL support searching by patient on the PrimaryCancerCondition resource

			  )
			  versions :r4
			end

			search_params = {
			  'patient': @instance.patient_id
			}

			reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
			assert_response_ok(reply)
			assert_bundle_response(reply)

			resource_count = reply&.resource&.entry&.length || 0
			@resources_found = true if resource_count.positive?

			skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

			@primary_cancer_condition = reply&.resource&.entry&.first&.resource
			@primary_cancer_condition_ary = fetch_all_bundled_resources(reply&.resource)
			save_resource_ids_in_bundle(versioned_resource_class('Condition'), reply)
			save_delayed_sequence_references(@primary_cancer_condition_ary)
			validate_search_reply(versioned_resource_class('Condition'), reply, search_params)
		  end
=end
=begin
		  test :patient_search do
			metadata do
			  id '01'
			  name 'Server rejects ECOG Performance Status search without authorization'
			  #link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
			  link 'http://build.fhir.org/ig/HL7/fhir-mCODE-ig/branches/master/StructureDefinition-obf-PrimaryCancerCondition.html'
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

			reply = get_resource_by_params(versioned_resource_class('PrimaryCancerCondition'), search_params)
			@client.set_bearer_token(@instance.token)
			assert_response_unauthorized reply
		  end

		  test 'Server returns expected results from PrimaryCancerCondition search by patient' do
			metadata do
			  id '02'
			  link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
			  description %(

				A server SHALL support searching by patient on the PrimaryCancerCondition resource

			  )
			  versions :r4
			end

			search_params = {
			  'patient': @instance.patient_id
			}

			reply = get_resource_by_params(versioned_resource_class('PrimaryCancerCondition'), search_params)
			assert_response_ok(reply)
			assert_bundle_response(reply)

			resource_count = reply&.resource&.entry&.length || 0
			@resources_found = true if resource_count.positive?

			skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

			@allergy_intolerance = reply&.resource&.entry&.first&.resource
			@allergy_intolerance_ary = fetch_all_bundled_resources(reply&.resource)
			save_resource_ids_in_bundle(versioned_resource_class('PrimaryCancerCondition'), reply)
			save_delayed_sequence_references(@allergy_intolerance_ary)
			validate_search_reply(versioned_resource_class('PrimaryCancerCondition'), reply, search_params)
		  end

		  test 'Server returns expected results from PrimaryCancerCondition search by patient+clinical-status' do
			metadata do
			  id '03'
			  link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
			  optional
			  description %(

				A server SHOULD support searching by patient+clinical-status on the PrimaryCancerCondition resource

			  )
			  versions :r4
			end

			skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
			assert !@allergy_intolerance.nil?, 'Expected valid PrimaryCancerCondition resource to be present'

			search_params = {
			  'patient': @instance.patient_id,
			  'clinical-status': get_value_for_search_param(resolve_element_from_path(@allergy_intolerance_ary, 'clinicalStatus'))
			}
			search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

			reply = get_resource_by_params(versioned_resource_class('PrimaryCancerCondition'), search_params)
			validate_search_reply(versioned_resource_class('PrimaryCancerCondition'), reply, search_params)
			assert_response_ok(reply)
		  end

		  test :read_interaction do
			metadata do
			  id '04'
			  name 'PrimaryCancerCondition read interaction supported'
			  link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
			  description %(
				A server SHALL support the PrimaryCancerCondition read interaction.
			  )
			  versions :r4
			end

			skip_if_not_supported(:PrimaryCancerCondition, [:read])
			skip 'No PrimaryCancerCondition resources could be found for this patient. Please use patients with more information.' unless @resources_found

			validate_read_reply(@allergy_intolerance, versioned_resource_class('PrimaryCancerCondition'))
		  end

		  test :vread_interaction do
			metadata do
			  id '05'
			  name 'PrimaryCancerCondition vread interaction supported'
			  link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
			  description %(
				A server SHOULD support the PrimaryCancerCondition vread interaction.
			  )
			  versions :r4
			end

			skip_if_not_supported(:PrimaryCancerCondition, [:vread])
			skip 'No PrimaryCancerCondition resources could be found for this patient. Please use patients with more information.' unless @resources_found

			validate_vread_reply(@allergy_intolerance, versioned_resource_class('PrimaryCancerCondition'))
		  end

		  test :history_interaction do
			metadata do
			  id '06'
			  name 'PrimaryCancerCondition history interaction supported'
			  link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
			  description %(
				A server SHOULD support the PrimaryCancerCondition history interaction.
			  )
			  versions :r4
			end

			skip_if_not_supported(:PrimaryCancerCondition, [:history])
			skip 'No PrimaryCancerCondition resources could be found for this patient. Please use patients with more information.' unless @resources_found

			validate_history_reply(@allergy_intolerance, versioned_resource_class('PrimaryCancerCondition'))
		  end

		  test 'Server returns the appropriate resources from the following _revincludes: Provenance:target' do
			metadata do
			  id '07'
			  link 'https://www.hl7.org/fhir/search.html#revinclude'
			  description %(
				A Server SHALL be capable of supporting the following _revincludes: Provenance:target
			  )
			  versions :r4
			end

			search_params = {
			  'patient': @instance.patient_id
			}

			search_params['_revinclude'] = 'Provenance:target'
			reply = get_resource_by_params(versioned_resource_class('PrimaryCancerCondition'), search_params)
			assert_response_ok(reply)
			assert_bundle_response(reply)
			provenance_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Provenance' }
			assert provenance_results, 'No Provenance resources were returned from this search'
		  end

		  test 'PrimaryCancerCondition resources associated with Patient conform to US Core R4 profiles' do
			metadata do
			  id '08'
			  link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-PrimaryCancerCondition'
			  description %(

				This test checks if the resources returned from prior searches conform to the US Core profiles.
				This includes checking for missing data elements and valueset verification.

			  )
			  versions :r4
			end

			skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
			test_resources_against_profile('PrimaryCancerCondition')
		  end

		  test 'At least one of every must support element is provided in any PrimaryCancerCondition for this patient.' do
			metadata do
			  id '09'
			  link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
			  description %(

				US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
				This will look through all PrimaryCancerCondition resources returned from prior searches to see if any of them provide the following must support elements:

				PrimaryCancerCondition.clinicalStatus

				PrimaryCancerCondition.verificationStatus

				PrimaryCancerCondition.code

				PrimaryCancerCondition.patient

			  )
			  versions :r4
			end

			skip 'No resources appear to be available for this patient. Please use patients with more information' unless @allergy_intolerance_ary&.any?
			must_support_confirmed = {}
			must_support_elements = [
			  'PrimaryCancerCondition.clinicalStatus',
			  'PrimaryCancerCondition.verificationStatus',
			  'PrimaryCancerCondition.code',
			  'PrimaryCancerCondition.patient'
			]
			must_support_elements.each do |path|
			  @allergy_intolerance_ary&.each do |resource|
				truncated_path = path.gsub('PrimaryCancerCondition.', '')
				must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
				break if must_support_confirmed[path]
			  end
			  resource_count = @allergy_intolerance_ary.length

			  skip "Could not find #{path} in any of the #{resource_count} provided PrimaryCancerCondition resource(s)" unless must_support_confirmed[path]
			end
			@instance.save!
		  end

		  test 'All references can be resolved' do
			metadata do
			  id '10'
			  link 'http://hl7.org/fhir/references.html'
			  description %(
				This test checks if references found in resources from prior searches can be resolved.
			  )
			  versions :r4
			end

			skip_if_not_supported(:PrimaryCancerCondition, [:search, :read])
			skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

			validate_reference_resolutions(@allergy_intolerance)
		  end
=end
		end
	  end
	end

