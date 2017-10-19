module Crucible
  module App
    class Test

      attr_accessor :response
      attr_accessor :url
      attr_accessor :token
      attr_accessor :patient_id
      attr_accessor :scopes
      attr_accessor :client
      attr_accessor :version
      attr_accessor :klass_header
      attr_accessor :conformance_klass
      attr_accessor :supporting_resources
      attr_accessor :vital_signs
      attr_accessor :accessible_resources
      attr_accessor :conformance
      attr_accessor :readable_resource_names

      def initialize(url, token_params, response)
        @url = url
        @response = response

        @response.start_table('Crucible Test Results',['Status','Description','Detail'])

        # Get token, patient id, and scopes for testing
        @token = token_params['access_token']
        @patient_id = token_params['patient']
        @scopes = token_params['scope']
        if @scopes.nil?
          @scopes = Crucible::App::Config.get_scopes(url)
        end

        # Configure the FHIR Client
        @client = FHIR::Client.new(url)
        @version = @client.detect_version
        @client.set_bearer_token(@token)
        @client.default_json

        # All supporting resources
        if @version == :dstu2
          @klass_header = "FHIR::DSTU2::"
          @conformance_klass = FHIR::DSTU2::Conformance
          @supporting_resources = [
            FHIR::DSTU2::AllergyIntolerance, FHIR::DSTU2::CarePlan, FHIR::DSTU2::Condition,
            FHIR::DSTU2::DiagnosticOrder, FHIR::DSTU2::DiagnosticReport, FHIR::DSTU2::Encounter,
            FHIR::DSTU2::FamilyMemberHistory, FHIR::DSTU2::Goal, FHIR::DSTU2::Immunization,
            FHIR::DSTU2::List, FHIR::DSTU2::Procedure, FHIR::DSTU2::MedicationAdministration,
            FHIR::DSTU2::MedicationDispense, FHIR::DSTU2::MedicationOrder,
            FHIR::DSTU2::MedicationStatement, FHIR::DSTU2::Observation, FHIR::DSTU2::RelatedPerson
          ]
          # Vital Signs includes these codes as defined in http://loinc.org
          @vital_signs = {
            '9279-1' => 'Respiratory rate',
            '8867-4' => 'Heart rate',
            '2710-2' => 'Oxygen saturation in Capillary blood by Oximetry',
            '55284-4' => 'Blood pressure systolic and diastolic',
            '8480-6' => 'Systolic blood pressure',
            '8462-4' => 'Diastolic blood pressure',
            '8310-5' => 'Body temperature',
            '8302-2' => 'Body height',
            '8306-3' => 'Body height --lying',
            '8287-5' => 'Head Occipital-frontal circumference by Tape measure',
            '3141-9' => 'Body weight Measured',
            '39156-5' => 'Body mass index (BMI) [Ratio]',
            '3140-1' => 'Body surface area Derived from formula',
            '59408-5' => 'Oxygen saturation in Arterial blood by Pulse oximetry',
            '8478-0' => 'Mean blood pressure'
          }
        elsif @version == :stu3
          @klass_header = "FHIR::"
          @conformance_klass = FHIR::CapabilityStatement
          @supporting_resources = [
            FHIR::AllergyIntolerance, FHIR::CarePlan, FHIR::CareTeam, FHIR::Condition, FHIR::Device,
            FHIR::DiagnosticReport, FHIR::Goal, FHIR::Immunization, FHIR::MedicationRequest,
            FHIR::MedicationStatement, FHIR::Observation, FHIR::Procedure, FHIR::RelatedPerson, FHIR::Specimen
          ]
          # Vital Signs includes these codes as defined in http://hl7.org/fhir/STU3/observation-vitalsigns.html
          @vital_signs = {
            '85353-1' => 'Vital signs, weight, height, head circumference, oxygen saturation and BMI panel',
            '9279-1' => 'Respiratory Rate',
            '8867-4' => 'Heart rate',
            '59408-5' => 'Oxygen saturation in Arterial blood by Pulse oximetry',
            '8310-5' => 'Body temperature',
            '8302-2' => 'Body height',
            '8306-3' => 'Body height --lying',
            '8287-5' => 'Head Occipital-frontal circumference by Tape measure',
            '29463-7' => 'Body weight',
            '39156-5' => 'Body mass index (BMI) [Ratio]',
            '85354-9' => 'Blood pressure systolic and diastolic',
            '8480-6' => 'Systolic blood pressure',
            '8462-4' => 'Diastolic blood pressure'
          }
        end

        # Parse accessible resources from scopes
        accessible_resource_names = @scopes.scan(/patient\/(.*?)\.[read|\*]/)
        @accessible_resources = []
        if accessible_resource_names.include?(["*"])
          @accessible_resources = @supporting_resources.dup
        else
          @accessible_resources = accessible_resource_names.map {|w| Object.const_get("#{@klass_header}#{w.first}")}
        end

        # Get the conformance statement
        @conformance = @client.conformance_statement
        conformance_details = @conformance.to_hash

        puts "FHIR Version: #{conformance_details['fhirVersion']}"

        # Get read capabilities
        @readable_resource_names = []
        @readable_resource_names = conformance_details['rest'][0]['resource'].select {|r|
          r['interaction'].include?({"code"=>"read"})
        }.map {|n| n['type']}

      end

      def run_patient

        # Get the patient demographics
        patient = @client.read(Object.const_get("#{@klass_header}Patient"), @patient_id).resource
        @response.assert('Patient Successfully Retrieved',patient.is_a?(Object.const_get("#{@klass_header}Patient")),patient.id)
        patient_details = patient.to_hash
        puts "Patient: #{patient_details['id']} #{patient_details['name']}"

        # DAF/US-Core CCDS
        @response.assert('Patient Name',patient_details['name'],patient_details['name'])
        @response.assert('Patient Gender',patient_details['gender'],patient_details['gender'])
        @response.assert('Patient Date of Birth',patient_details['birthDate'],patient_details['birthDate'])
        # US Extensions
        puts 'Examining Patient for US-Core Extensions'
        extensions = {
          'Race' => 'http://hl7.org/fhir/StructureDefinition/us-core-race',
          'Ethnicity' => 'http://hl7.org/fhir/StructureDefinition/us-core-ethnicity',
          'Religion' => 'http://hl7.org/fhir/StructureDefinition/us-core-religion',
          'Mother\'s Maiden Name' => 'http://hl7.org/fhir/StructureDefinition/patient-mothersMaidenName',
          'Birth Place' => 'http://hl7.org/fhir/StructureDefinition/birthPlace'
        }
        required_extensions = ['Race','Ethnicity']
        extensions.each do |name,url|
          detail = nil
          check = :not_found
          if patient_details['extension']
            detail = patient_details['extension'].find{|e| e['url']==url }
            check = !detail.nil? if required_extensions.include?(name)
          elsif required_extensions.include?(name)
            check = false
          end
          @response.assert("Patient #{name}", check, detail)
        end
        @response.assert('Patient Preferred Language',(patient_details['communication'] && patient_details['communication'].find{|c|c['language'] && c['preferred']}),patient_details['communication'])

      end

      def run_smoking_status

        # Get the patient's smoking status
        # {"coding":[{"system":"http://loinc.org","code":"72166-2"}]}
        puts 'Getting Smoking Status'
        search_reply = @client.search(Object.const_get("#{@klass_header}Observation"), search: { parameters: { 'patient' => @patient_id, 'code' => 'http://loinc.org|72166-2'}})
        search_reply_length = search_reply.try(:resource).try(:entry).try(:length)
        unless search_reply_length.nil?
          if @accessible_resources.include?(Object.const_get("#{@klass_header}Observation")) # If resource is in scopes
            if search_reply_length == 0
              if @readable_resource_names.include?("Observation")
                @response.assert("Smoking Status",:not_found)
              else
                @response.assert("Smoking Status",:skip,"Read capability for resource not in conformance statement.")
              end
            elsif search_reply_length > 0
              @response.assert("Smoking Status",true,(search_reply.resource.entry.first.to_fhir_json rescue nil))
            else
              if @readable_resource_names.include?("Observation") # If comformance claims read capability for resource
                @response.assert("Smoking Status",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
              else
                @response.assert("Smoking Status",:skip,"Read capability for resource not in conformance statement.")
              end
            end
          else # If resource is not in scopes
            if search_reply_length > 0
              @response.assert("Smoking Status",false,"Resource provided without required scopes.")
            else
              @response.assert("Smoking Status",:skip,"Access not granted through scopes.")
            end
          end
        else
          if @readable_resource_names.include?("Observation") # If comformance claims read capability for resource
            @response.assert("Smoking Status",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
          else
            @response.assert("Smoking Status",:skip,"Read capability for resource not in conformance statement.")
          end
        end

      end

      def run_allergyintolerance

        # Get the patient's allergies
        # There should be at least one. No known allergies should have a negated entry.
        # Include these codes as defined in http://snomed.info/sct
        #   Code	     Display
        #   160244002	No Known Allergies
        #   429625007	No Known Food Allergies
        #   409137002	No Known Drug Allergies
        #   428607008	No Known Environmental Allergy
        puts 'Getting AllergyIntolerances'
        search_reply = @client.search(Object.const_get("#{@klass_header}AllergyIntolerance"), search: { parameters: { 'patient' => @patient_id } })
        search_reply_length = search_reply.try(:resource).try(:entry).try(:length)
        unless search_reply_length.nil?
          if @accessible_resources.include?(Object.const_get("#{@klass_header}AllergyIntolerance")) # If resource is in scopes
            if search_reply_length == 0
              if @readable_resource_names.include?("AllergyIntolerance")
                @response.assert("AllergyIntolerances",false,"No Known Allergies.");
              else
                @response.assert("AllergyIntolerances",:skip,"Read capability for resource not in conformance statement.")
              end
            elsif search_reply_length > 0
              @response.assert("AllergyIntolerances",true,"Found #{search_reply_length} AllergyIntolerance.")
            else
              if @readable_resource_names.include?("AllergyIntolerance") # If comformance claims read capability for resource
                @response.assert("AllergyIntolerances",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
              else
                @response.assert("AllergyIntolerances",:skip,"Read capability for resource not in conformance statement.")
              end
            end
          else # If resource is not in scopes
            if search_reply_length > 0
              @response.assert("AllergyIntolerances",false,"Resource provided without required scopes.")
            else
              @response.assert("AllergyIntolerances",:skip,"Access not granted through scopes.")
            end
          end
        else
          if @readable_resource_names.include?("AllergyIntolerance") # If comformance claims read capability for resource
            @response.assert("AllergyIntolerances",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
          else
            @response.assert("AllergyIntolerances",:skip,"Read capability for resource not in conformance statement.")
          end
        end

      end

      def run_vital_signs

        puts 'Getting Vital Signs / Observations'
        @vital_signs.each do |code,display|
          self.test_vital_sign(code, display)
        end

      end

      def test_vital_sign(code, display)

        search_reply = @client.search(Object.const_get("#{@klass_header}Observation"), search: { parameters: { 'patient' => @patient_id, 'code' => "http://loinc.org|#{code}" } })
        search_reply_length = search_reply.try(:resource).try(:entry).try(:length)
        unless search_reply_length.nil?
          if @accessible_resources.include?(Object.const_get("#{@klass_header}Observation")) # If resource is in scopes
            if search_reply_length == 0
              if @readable_resource_names.include?("Observation")
                @response.assert("Vital Sign: #{display}",:not_found)
              else
                @response.assert("Vital Sign: #{display}",:skip,"Read capability for resource not in conformance statement.")
              end
            elsif search_reply_length > 0
              @response.assert("Vital Sign: #{display}",true,"Found #{search_reply_length} Vital Sign: #{display}.")
            else
              if @readable_resource_names.include?("Observation") # If comformance claims read capability for resource
                @response.assert("Vital Sign: #{display}",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
              else
                @response.assert("Vital Sign: #{display}",:skip,"Read capability for resource not in conformance statement.")
              end
            end
          else # If resource is not in scopes
            if search_reply_length > 0
              @response.assert("Vital Sign: #{display}",false,"Resource provided without required scopes.")
            else
              @response.assert("Vital Sign: #{display}",:skip,"Access not granted through scopes.")
            end
          end
        else
          if @readable_resource_names.include?("Observation") # If comformance claims read capability for resource
            @response.assert("Vital Sign: #{display}",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
          else
            @response.assert("Vital Sign: #{display}",:skip,"Read capability for resource not in conformance statement.")
          end
        end

      end

      def run_supporting_resources

        puts 'Checking for Supporting Resources'
        @supporting_resources.reject{|k| [Object.const_get("#{@klass_header}AllergyIntolerance"), Object.const_get("#{@klass_header}Observation")].include?(k)}.each do |klass| # Already tested AllergyIntolerance and Observation
          puts "Getting #{klass.name.demodulize}s"
          self.test_supporting_resource(klass)
        end

        # DAF (DSTU2)-----------------------------
    #    # AllergyIntolerance
    #    # DiagnosticOrder
    #    # DiagnosticReport
    #    # Encounter
    #    # FamilyMemberHistory
    #    # Immunization
        # Results (Observation)
        # Medication
    #    # MedicationStatement
    #    # MedicationAdministration
    #    # MedicationDispense
    #    # MedicationOrder
    #    # Patient
    #    # Condition
    #    # Procedure
    #    # SmokingStatus (Observation)
    #    # VitalSigns (Observation)
        # List
    #    # Additional Resources: RelatedPerson, Specimen

        # US Core (STU3)-----------------------------
        # AllergyIntolerance
        # CareTeam
        # Condition
        # Device
        # DiagnosticReport
        # Goal
        # Immunization
        # Location (can't search by patient)
        # Medication (can't search by patient)
        # MedicationRequest
        # MedicationStatement
        # Practitioner (can't search by patient)
        # Procedure
        # Results (Observation)
        # SmokingStatus (Observation
        # CarePlan
        # Organization (can't search by patient)
        # Patient
        # VitalSigns (Observation)
        # Additional Resources: RelatedPerson, Specimen

        # ARGONAUTS ----------------------
        # 	CCDS Data Element	         FHIR Resource
    #    # (1)	Patient Name	             Patient
    #    # (2)	Sex	                        Patient
    #    # (3)	Date of birth	              Patient
    #    # (4)	Race	                       Patient
    #    # (5)	Ethnicity	                  Patient
    #    # (6)	Preferred language	       Patient
    #    # (7)	Smoking status	           Observation
    #    # (8)	Problems	                 Condition
    #    # (9)	Medications	                Medication, MedicationStatement, MedicationOrder
    #    # (10)	Medication allergies	    AllergyIntolerance
    #    # (11)	Laboratory test(s)	      Observation, DiagnosticReport
    #    # (12)	Laboratory value(s)/result(s)	Observation, DiagnosticReport
    #    # (13)	Vital signs	             Observation
        # (14)	(no longer required)	-
    #    # (15)	Procedures	              Procedure
    #    # (16)	Care team member(s)	     CarePlan
    #    # (17)	Immunizations	           Immunization
        # (18)	Unique device identifier(s) for a patient’s implantable device(s)	Device
    #    # (19)	Assessment and plan of treatment	CarePlan
    #    # (20)	Goals	                   Goal
    #    # (21)	Health concerns	         Condition
        # --------------------------------
        # Date range search requirements are included in the Quick Start section for the following resources -
        # Vital Signs, Laboratory Results, Goals, Procedures, and Assessment and Plan of Treatment.

      end

      def test_supporting_resource(klass)

        search_reply = @client.search(klass, search: { parameters: { 'patient' => @patient_id } })
        search_reply_length = search_reply.try(:resource).try(:entry).try(:length)
        unless search_reply_length.nil?
          if @accessible_resources.include?(klass) # If resource is in scopes
            if search_reply_length == 0
              if @readable_resource_names.include?(klass.name.demodulize)
                @response.assert("#{klass.name.demodulize}s",:not_found)
              else
                @response.assert("#{klass.name.demodulize}s",:skip,"Read capability for resource not in conformance statement.")
              end
            elsif search_reply_length > 0
              @response.assert("#{klass.name.demodulize}s",true,"Found #{search_reply_length} #{klass.name.demodulize}.")
            else
              if @readable_resource_names.include?(klass.name.demodulize) # If comformance claims read capability for resource
                @response.assert("#{klass.name.demodulize}s",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
              else
                @response.assert("#{klass.name.demodulize}s",:skip,"Read capability for resource not in conformance statement.")
              end
            end
          else # If resource is not in scopes
            if search_reply_length > 0
              @response.assert("#{klass.name.demodulize}s",false,"Resource provided without required scopes.")
            else
              @response.assert("#{klass.name.demodulize}s",:skip,"Access not granted through scopes.")
            end
          end
        else
          if @readable_resource_names.include?(klass.name.demodulize) # If comformance claims read capability for resource
            @response.assert("#{klass.name.demodulize}s",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
          else
            @response.assert("#{klass.name.demodulize}s",:skip,"Read capability for resource not in conformance statement.")
          end
        end

      end

      def score

        # Output a summary
        total = @response.pass + @response.not_found + @response.skip + @response.fail
        @response.assert("#{((@response.pass.to_f / total.to_f)*100.0).round}% (#{@response.pass} of #{total})",true,'Total tests passed')
        @response.assert("#{((@response.not_found.to_f / total.to_f)*100.0).round}% (#{@response.not_found} of #{total})",:not_found,'Total tests "not found" or inconclusive')
        @response.assert("#{((@response.skip.to_f / total.to_f)*100.0).round}% (#{@response.skip} of #{total})",:skip,'Total tests skipped')
        @response.assert("#{((@response.fail.to_f / total.to_f)*100.0).round}% (#{@response.fail} of #{total})",false,'Total tests failed')
        @response.end_table

      end

    end
  end
end
