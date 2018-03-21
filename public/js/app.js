$(function(){

  function indent(value) {
    var firstCharacter = value.charAt(0)
    if(['{','['].indexOf(firstCharacter) >= 0){
      return vkbeautify.json(value, 2);
    } else if(firstCharacter == '<'){
      return vkbeautify.xml(value, 2)
    }else{
      return value;
    }
  }

  $('.sequence-main').on('click', function(e) {
    if(e.target.getAttribute('role') !== 'button' && e.target.className !== 'result-details-clickable'){
      $(this).parent().find('.collapse').collapse('toggle');
    }
  });

  $('.sequence-row').on('show.bs.collapse', function() {
    $(this).find('.oi-chevron-right').removeClass('oi-chevron-right').addClass('oi-chevron-bottom');
  });

  $('.sequence-row').on('hide.bs.collapse', function() {
    $(this).find('.oi-chevron-bottom').removeClass('oi-chevron-bottom').addClass('oi-chevron-right');
  });

  $('.disable-buttons').each(function(el){
    $(this).find('.btn').attr('disabled', true)

    $(this).attr('title', $(this).data('preconditionDescription'))
                        .attr('data-toggle','tooltip');
  });

  $('.result-details li').on('click', function() {
    if($(this).data('testingInstanceId') && $(this).data('testResultId')){
      var url = '/smart/' + $(this).data('testingInstanceId') + '/test_result/' + $(this).data('testResultId');
      $("#testResultDetailsModal").find('.modal-content').load(url, function(value){
        $(this).find("pre>code").each(function(el){
          let $el = $(this)
          let content = $el.html()
          try{
            if(content && content.length > 0){
              content = indent($el.html())
            }
          } catch (ex) {
            console.log('Error indenting: ' + ex)
          }
          $el.html(content)
        });

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

}); 
