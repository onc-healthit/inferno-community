module Inferno
  class App
    module Helpers
      module BrowserLogic

        def js_hide_wait_modal
          "<script>console.log('hide_wait_modal');$('#WaitModal').modal('hide');</script>"
        end

        def js_show_test_modal
          "<script>console.log('show_test_modal');$('#testsRunningModal').modal('show')</script>"
        end

        def js_stayalive(time)
          "<script>console.log('Time running: ' + #{time})</script>"
        end

        def js_update_result(sequence, result, count, total)
            cancelBtn = ""
            cancelBtn = "<a href=\"sequence_result/#{sequence.sequence_result.id}/cancel\" class=\"btn btn-secondary\">Cancel Sequence</a>" if(sequence.sequence_result)
          "<script>console.log('js_update_result');$('#testsRunningModal').find('.number-complete:last').html('(#{count} of #{total} #{sequence.class.title} tests complete)');$('#testsRunningModal .modal-footer').html('#{cancelBtn}');</script>"
        end

        def js_redirect(location)
          "<script>console.log('js_window_location'); window.location = '#{location}'</script>"
        end

        def js_redirect_modal(location, sequence, instance)
          # cancelBtn = "<a href=\"sequence_result/#{sequence.id}/cancel\" class=\"btn btn-secondary\">Cancel Sequence</a>"
          okBtn = "<a href=\"#{location}\" class=\"btn btn-primary\">Continue</a>"
          warningTxt = "Inferno will now redirect you to an external website for user authorization.  For this test sequence to complete successfully, you will need to select a patient and authorize the Inferno client to access their data.  Once you authorize the Inferno client to access patient data, you should be redirected back to Inferno.  If something goes wrong, you can always return to Inferno at <a href=\"#{instance.base_url}#{base_path}/#{instance.id}\">#{instance.base_url}#{base_path}/#{instance.id}</a>.<br/><br/>"

          "<script>console.log('js_redirect_modal');$('#testsRunningModal').find('.modal-body').html('#{warningTxt} <textarea readonly class=\"form-control\" rows=\"3\">#{location}</textarea>'); $('#testsRunningModal').find('.modal-footer').append('#{okBtn}');</script>"
        end

        def js_next_sequence(sequences)
          # "<script>console.log('js_next_sequence');$('#testsRunningModal').find('.number-complete-container').append('<div class=\'number-complete\'></div>');</script>"
        end

        def markdown_to_html(markdown)
          # we need to remove the 'normal' level of indentation before passing to markdown editor
          # find the minimum non-zero spacing indent and reduce by that many for all lines (note, did't make work for tabs)
          natural_indent = markdown.lines.collect{|l| l.index(/[^ ]/)}.select{|l| !l.nil? && l> 0}.min || 0
          unindented_markdown = markdown.lines.map{|l| l[natural_indent..-1] || "\n"}.join
          Kramdown::Document.new(unindented_markdown).to_html
        end
      end
    end
  end
end
