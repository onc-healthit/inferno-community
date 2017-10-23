module Crucible
  module App
    class Test

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

    end
  end
end
