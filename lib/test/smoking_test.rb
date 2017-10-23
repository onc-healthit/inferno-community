module Crucible
  module App
    class Test

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

    end
  end
end
