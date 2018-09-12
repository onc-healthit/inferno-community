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
          "<script>console.log('js_update_result');$('#testsRunningModal').find('.number-complete:last').html('(#{count} of #{total} #{sequence.class.title} tests complete)');</script>"
        end

        def js_redirect(location)
          "<script>console.log('js_window_location'); window.location = '#{location}'</script>"
        end

        def js_redirect_modal(location)
          "<script>console.log('js_redirect_modal');$('#testsRunningModal').find('.modal-body').html('Redirecting to <textarea readonly class=\"form-control\" rows=\"3\">#{location}</textarea>');</script>"
        end

        def js_next_sequence(sequences)
          # "<script>console.log('js_next_sequence');$('#testsRunningModal').find('.number-complete-container').append('<div class=\'number-complete\'></div>');</script>"
        end
      end
    end
  end
end
