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

  var isConfidential = $('#is_confidential'),
      secretEntry = $('#client_secret_form_group')


  isConfidential.on('click', function() {
      if($(this).is(':checked')) {
          $('#client_secret_form_group').removeClass("d-none");
          secretEntry.find('input').attr('required', true);
      } else {
          $('#client_secret_form_group').addClass("d-none");
          secretEntry.find('input').attr('required', false);
      }
  });


  // $('.sequence-main').on('click', function(e) {
  //   if(e.target.getAttribute('role') !== 'button' && e.target.className !== 'result-details-clickable'){
  //     $(this).parent().find('.collapse').collapse('toggle');
  //   }
  // });

  $('.sequence-expand-button').click(function () {
    let button = $(this)
    button.parent().find('.collapse').collapse('toggle');
    if (button.text().indexOf("Show") > 0) {
      button.html("<span class='oi oi-chevron-top'></span> Hide Details")
    }
    else {
      button.html("<span class='oi oi-chevron-bottom'></span> Show Details")
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
    let details = $(window.location.hash + "-details")
    details.collapse('show')
    details.parent().find('.sequence-expand-button').html("<span class='oi oi-chevron-top'></span> Hide Details")
  }

  $('[data-toggle="tooltip"]').tooltip()

  $('#WaitModal').modal('show');

}); 
