module Crucible
  module App
    class Test

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

    end
  end
end
