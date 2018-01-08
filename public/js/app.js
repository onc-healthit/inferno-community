Stickyfill.add(document.querySelectorAll('.sticky'));

$(function(){

  $('[data-toggle="tooltip"]').tooltip()

  $('.scorecard-row').on('show.bs.collapse', function() {
    $(this).find('.oi-chevron-right').removeClass('oi-chevron-right').addClass('oi-chevron-bottom');
  });

  $('.scorecard-row').on('hide.bs.collapse', function() {
    $(this).find('.oi-chevron-bottom').removeClass('oi-chevron-bottom').addClass('oi-chevron-right');
  });

  $('.result-details li').on('click', function() {
    alert('show test information; links to spec, exact wording, request & responses, warnings');
  })

})
