module Crucible
  module App
    class Test

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

    end
  end
end
