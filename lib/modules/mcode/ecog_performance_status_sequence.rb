# frozen_string_literal: true

module Inferno
  module Sequence
    class ECOGPerformanceStatusSequence < SequenceBase
		title 'ECOGPerformanceStatus Tests'

		description 'Verify that ECOG Performance Status resources on the FHIR server follow the mCode Implementation Guide'

		test_id_prefix 'ECOG'

		requires :token, :patient_id
		conformance_supports :ECOG

		  def validate_resource_item(resource, property, value)
			case property

			when 'clinical-status'
			  value_found = can_resolve_path(resource, 'clinicalStatus.coding.code') { |value_in_resource| value_in_resource == value }
			  assert value_found, 'clinical-status on resource does not match clinical-status requested'

			when 'patient'
			  value_found = can_resolve_path(resource, 'patient.reference') { |reference| [value, 'Patient/' + value].include? reference }
			  assert value_found, 'patient on resource does not match patient requested'

			end
		  end

		  details %(
			The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
		  )

		  @resources_found = false

		  test :unauthorized_search do
			metadata do
			  id '01'
			  name 'Server rejects ECOG Performance Status search without authorization'
			  #link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
			  link 'http://build.fhir.org/ig/HL7/fhir-mCODE-ig/branches/master/StructureDefinition-obf-ECOGPerformanceStatus.html'
			  description %(
				A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
			  )
			  versions :r4
			end

			skip_if_not_supported(:ECOGPerformanceStatus, [:search])

			@client.set_no_auth
			omit 'Do not test if no bearer token set' if @instance.token.blank?

			search_params = {
			  'patient': @instance.patient_id
			}

			reply = get_resource_by_params(versioned_resource_class('ECOGPerformanceStatus'), search_params)
			@client.set_bearer_token(@instance.token)
			assert_response_unauthorized reply
		  end
=begin
		  test 'Server returns expected results from ECOGPerformanceStatus search by patient' do
			metadata do
			  id '02'
			  link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
			  description %(

				A server SHALL support searching by patient on the ECOGPerformanceStatus resource

			  )
			  versions :r4
			end

			search_params = {
			  'patient': @instance.patient_id
			}

			reply = get_resource_by_params(versioned_resource_class('ECOGPerformanceStatus'), search_params)
			assert_response_ok(reply)
			assert_bundle_response(reply)

			resource_count = reply&.resource&.entry&.length || 0
			@resources_found = true if resource_count.positive?

			skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

			@allergy_intolerance = reply&.resource&.entry&.first&.resource
			@allergy_intolerance_ary = fetch_all_bundled_resources(reply&.resource)
			save_resource_ids_in_bundle(versioned_resource_class('ECOGPerformanceStatus'), reply)
			save_delayed_sequence_references(@allergy_intolerance_ary)
			validate_search_reply(versioned_resource_class('ECOGPerformanceStatus'), reply, search_params)
		  end

		  test 'Server returns expected results from ECOGPerformanceStatus search by patient+clinical-status' do
			metadata do
			  id '03'
			  link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
			  optional
			  description %(

				A server SHOULD support searching by patient+clinical-status on the ECOGPerformanceStatus resource

			  )
			  versions :r4
			end

			skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
			assert !@allergy_intolerance.nil?, 'Expected valid ECOGPerformanceStatus resource to be present'

			search_params = {
			  'patient': @instance.patient_id,
			  'clinical-status': get_value_for_search_param(resolve_element_from_path(@allergy_intolerance_ary, 'clinicalStatus'))
			}
			search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

			reply = get_resource_by_params(versioned_resource_class('ECOGPerformanceStatus'), search_params)
			validate_search_reply(versioned_resource_class('ECOGPerformanceStatus'), reply, search_params)
			assert_response_ok(reply)
		  end

		  test :read_interaction do
			metadata do
			  id '04'
			  name 'ECOGPerformanceStatus read interaction supported'
			  link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
			  description %(
				A server SHALL support the ECOGPerformanceStatus read interaction.
			  )
			  versions :r4
			end

			skip_if_not_supported(:ECOGPerformanceStatus, [:read])
			skip 'No ECOGPerformanceStatus resources could be found for this patient. Please use patients with more information.' unless @resources_found

			validate_read_reply(@allergy_intolerance, versioned_resource_class('ECOGPerformanceStatus'))
		  end

		  test :vread_interaction do
			metadata do
			  id '05'
			  name 'ECOGPerformanceStatus vread interaction supported'
			  link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
			  description %(
				A server SHOULD support the ECOGPerformanceStatus vread interaction.
			  )
			  versions :r4
			end

			skip_if_not_supported(:ECOGPerformanceStatus, [:vread])
			skip 'No ECOGPerformanceStatus resources could be found for this patient. Please use patients with more information.' unless @resources_found

			validate_vread_reply(@allergy_intolerance, versioned_resource_class('ECOGPerformanceStatus'))
		  end

		  test :history_interaction do
			metadata do
			  id '06'
			  name 'ECOGPerformanceStatus history interaction supported'
			  link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
			  description %(
				A server SHOULD support the ECOGPerformanceStatus history interaction.
			  )
			  versions :r4
			end

			skip_if_not_supported(:ECOGPerformanceStatus, [:history])
			skip 'No ECOGPerformanceStatus resources could be found for this patient. Please use patients with more information.' unless @resources_found

			validate_history_reply(@allergy_intolerance, versioned_resource_class('ECOGPerformanceStatus'))
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
			reply = get_resource_by_params(versioned_resource_class('ECOGPerformanceStatus'), search_params)
			assert_response_ok(reply)
			assert_bundle_response(reply)
			provenance_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Provenance' }
			assert provenance_results, 'No Provenance resources were returned from this search'
		  end

		  test 'ECOGPerformanceStatus resources associated with Patient conform to US Core R4 profiles' do
			metadata do
			  id '08'
			  link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ECOGPerformanceStatus'
			  description %(

				This test checks if the resources returned from prior searches conform to the US Core profiles.
				This includes checking for missing data elements and valueset verification.

			  )
			  versions :r4
			end

			skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
			test_resources_against_profile('ECOGPerformanceStatus')
		  end

		  test 'At least one of every must support element is provided in any ECOGPerformanceStatus for this patient.' do
			metadata do
			  id '09'
			  link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
			  description %(

				US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
				This will look through all ECOGPerformanceStatus resources returned from prior searches to see if any of them provide the following must support elements:

				ECOGPerformanceStatus.clinicalStatus

				ECOGPerformanceStatus.verificationStatus

				ECOGPerformanceStatus.code

				ECOGPerformanceStatus.patient

			  )
			  versions :r4
			end

			skip 'No resources appear to be available for this patient. Please use patients with more information' unless @allergy_intolerance_ary&.any?
			must_support_confirmed = {}
			must_support_elements = [
			  'ECOGPerformanceStatus.clinicalStatus',
			  'ECOGPerformanceStatus.verificationStatus',
			  'ECOGPerformanceStatus.code',
			  'ECOGPerformanceStatus.patient'
			]
			must_support_elements.each do |path|
			  @allergy_intolerance_ary&.each do |resource|
				truncated_path = path.gsub('ECOGPerformanceStatus.', '')
				must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
				break if must_support_confirmed[path]
			  end
			  resource_count = @allergy_intolerance_ary.length

			  skip "Could not find #{path} in any of the #{resource_count} provided ECOGPerformanceStatus resource(s)" unless must_support_confirmed[path]
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

			skip_if_not_supported(:ECOGPerformanceStatus, [:search, :read])
			skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

			validate_reference_resolutions(@allergy_intolerance)
		  end
=end
		end
	  end
	end

