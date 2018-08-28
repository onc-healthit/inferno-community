$(function(){

  function indent(value) {
    var firstCharacter = value.trim().charAt(0)
    try{
      if(['{','['].indexOf(firstCharacter) >= 0){
        return JSON.stringify(JSON.parse(value),null,2);
      } else {
        return value;
      }
    } catch (e) {
      return value;
    }
  }

  $('input[type=radio][name=confidential_client]').on('change', function() {
   switch($(this).val()) {
     case 'true':
       $('.client-secret-container').show();
       break;
     case 'false':
       $('.client-secret-container').hide();
       break;
   }
  });


  // $('.sequence-main').on('click', function(e) {
  //   if(e.target.getAttribute('role') !== 'button' && e.target.className !== 'result-details-clickable'){
  //     $(this).parent().find('.collapse').collapse('toggle');
  //   }
  // });

  $('.sequence-expand-button').click(function (event) {
    event.preventDefault();
    let button = $(this)
    let details = $('#' + button.data('result-details'))
    details.collapse('toggle');
    if (button.text().indexOf("Show") > -1) {
      button.html("Hide Details")
    }
    else {
      button.html("Show Details")
    }
  });

  // $('.sequence-row').on('show.bs.collapse', function() {
  //   $(this).find('.oi-chevron-right').removeClass('oi-chevron-right').addClass('oi-chevron-bottom');
  // });

  // $('.sequence-row').on('hide.bs.collapse', function() {
  //   $(this).find('.oi-chevron-bottom').removeClass('oi-chevron-bottom').addClass('oi-chevron-right');
  // });

  $('.sequence-action button').click(function() {
    var sequence = $(this).data('sequence');
    // FIXME: This replaces the modal title with a regex'd sequence title, but it may not match (e.g., 'Dynamic Registration' vs. 'Dynamic Registration Sequence')
    $('#PrerequisitesModalTitle').html(sequence.replace(/(?<!^)([A-Z][a-z]|(?<=[a-z])[A-Z])/g, ' $1'))
    var requirements = []
    $('#PrerequisitesModal .form-group').each(function(){
      var requiredby = $(this).data('requiredby');
      var prerequisite = $(this).data('prerequisite');
      var show = false;
      if(requiredby){
        requiredby.split(',').forEach(function(item){
          if(item === sequence){
            show = true;
            requirements.push(prerequisite)
          }
        })
      }
      if(show){
        $(this).show()
      } else {
        $(this).hide();
      }
    });

    $('#PrerequisitesModal input[name=sequence]').val(sequence);
    $('#PrerequisitesModal input[name=required_fields]').val(requirements.join(','));

    // Confidential client special case
    if($('#confidential_client_on')[0].checked){
       $('.client-secret-container').show();
    } else {
       $('.client-secret-container').hide();
    }

    if(requirements.length === 0){
      $('#PrerequisitesModal form').submit();
    } else {
      $('#PrerequisitesModal').modal('show');
    }

  });

  $('.disable-buttons').each(function(){
    $(this).find('.btn').attr('disabled', true)

    $(this).attr('title', $(this).data('preconditionDescription'))
                        .attr('data-toggle','tooltip');
  });

  $('.result-details li').on('click', function() {
    if($(this).data('testingInstanceId') && $(this).data('testResultId')){
      var url = window.basePath + '/' + $(this).data('testingInstanceId') + '/test_result/' + $(this).data('testResultId');
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
    let sequence = $(window.location.hash)
    let details = $(window.location.hash + "-details")
    details.collapse('show')
    sequence.parents('.sequence-row').find('.sequence-expand-button').text("Hide Details")
  }

  $('[data-toggle="tooltip"]').tooltip()

  $('#WaitModal').modal('show');

}); 
