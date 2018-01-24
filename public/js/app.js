Stickyfill.add(document.querySelectorAll('.sticky'));

$(function(){

  $('.scorecard-row').on('click', function(e) {
    if(e.target.getAttribute('role') !== 'button' && e.target.className !== 'result-details-clickable'){
      $(this).find('.collapse').collapse('toggle');
    }
  });

  $('.scorecard-row').on('show.bs.collapse', function() {
    $(this).find('.oi-chevron-right').removeClass('oi-chevron-right').addClass('oi-chevron-bottom');
  });

  $('.scorecard-row').on('hide.bs.collapse', function() {
    $(this).find('.oi-chevron-bottom').removeClass('oi-chevron-bottom').addClass('oi-chevron-right');
  });

  $('.disable-buttons').each(function(el){
    $(this).find('.btn').attr('disabled', true)

    $(this).attr('title', $(this).data('preconditionDescription'))
                        .attr('data-toggle','tooltip');
  });

  $('.result-details li').on('click', function() {
    if($(this).data('testingInstanceId') && $(this).data('testResultId')){
      var url = '/instance/' + $(this).data('testingInstanceId') + '/test_result/' + $(this).data('testResultId');
      $("#testResultDetailsModal").find('.modal-content').load(url, function(){
        $("#testResultDetailsModal").modal('show');
      })
    }
  })

  $(":input[type=text][readonly='readonly']").on('click', function(){
    this.select();
  })

  if(window.location.hash.length > 0){
    $(window.location.hash + "Sequence-details").collapse('show')
  }

  $('[data-toggle="tooltip"]').tooltip()

  $('#WaitModal').modal('show');

})
