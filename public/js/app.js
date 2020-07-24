

$(function(){
  jQuery.extend({

    getQueryParameters : function(str) {
      return (str || document.location.search).replace(/(^\?)/,'').split("&").map(function(n){return n = n.split("="),this[n[0]] = n[1],this}.bind({}))[0];
    }
  
  });

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

  $('#report-link').on('click', function(){
    if($('#reportDiv')[0].innerHTML.trim().length === 0){
      $('#reportDiv').load('report');
    }
  });

  $(document.links).filter(function() {
    return this.hostname != window.location.hostname;
  }).attr('target', '_blank');

  $('.sequence-expand-button').click(function (event) {
    let button = $(this);
    if (button.text().indexOf("Show") > -1) {
      button.html("Hide Details");
    }
    else {
      button.html("Show Details");
    }
  });

  $('.sequence-details-more').click(function () {
    var button = $(this);
    var sequence = button.data('sequence');
     if(sequence){
      $('.help-details').each(function(){
        if($(this).data('sequence') === sequence){
          $(this).show();
          $('#help-modal-title').html($(this).data('sequence-title'));
           // FIXME: technically we don't hae to do this every time it is opened, only the first time
          $(this).find('a[href^="http"]').attr('target','_blank');
        } else {
          $(this).hide();
        }
      })
      $('#help-sequence-' + sequence).collapse('show')
       $('#help-modal').modal('show');
     }
  });

  $('.sequence-button').click(function(){
    var sequences = [],
        test_cases = [],
        variable_defaults = {},
        requirements = [],
        popupTitle = "",
        lockedVariables = [],
        skippedOnly = false,
        show_uris = false,
        show_bulk_registration_info = false;

    popupTitle = $(this).closest('.sequence-action-boundary').data('group');

    $('.input-instructions').hide();
    if($(this).data('groupId')){
      $('#input-instructions-' + $(this).data('groupId')).show();

      let lockedVars = $('#group-lock-variables-' + $(this).data('groupId')).data('lockVariables');
      
      if(lockedVars){
        lockedVariables = lockedVars.split(",")
      }
    }
    
    if($(this).data('skippedOnly')){
      skippedOnly = $(this).data('skippedOnly');
    }

    $(this).closest('.sequence-action-boundary').find('.test-case-data').each(function(){
      if(!skippedOnly || $(this).data('result') === 'skip')
      {
          sequences.push($(this).data('sequence'));
          test_cases.push($(this).data('testCase'));
          if($(this).data('variableDefaults')){
            let _this = $(this);
            $(this).data('variableDefaults').split(",").forEach(function(variable){
              if(_this.data('variableDefault'+variable) !== undefined){
                variable_defaults[variable] = _this.data('variableDefault'+variable);
              }
            })
          }
    
          if(!popupTitle){
            popupTitle = $(this).data('testCaseTitle');
          }

          if(!show_uris){
            show_uris = $(this).data('showUris');
          }
          if(!show_bulk_registration_info){
            show_bulk_registration_info = $(this).data('showBulkRegistrationInfo');
          }
      }

    });

    // clear out the existing contents
    $('.prerequisite-group').empty();
    $('.show-uris').hide();
    $('.show-bulk-registration-info').hide();
    $('.enabled-prerequisite-group-title').hide();
    $('.disabled-prerequisite-group-title').hide();
    $('.disabled-prerequisites').hide();
    $('.enabled-prerequisites').hide();

    //$('input[type=radio][name=confidential_client]').on('change', function() {
    $('#PrerequisitesModal').on('change', function(e) {
      if(e.target.id === 'confidential_client_on_active') {
        $('div[data-prerequisite="client_secret"]').show();
      } else if (e.target.id === 'confidential_client_off_active'){
        $('div[data-prerequisite="client_secret"]').hide();
      } else if (e.target.id === 'onc_sl_confidential_client_on_active'){
        $('div[data-prerequisite="onc_sl_client_secret"]').show();
      } else if (e.target.id === 'onc_sl_confidential_client_off_active'){
        $('div[data-prerequisite="onc_sl_client_secret"]').hide();
      } else if (e.target.id === 'check_bulk_jwks_url') {
        if (e.target.checked) {
          $('div[data-prerequisite="bulk_jwks_url_auth"]').show();
        } else {
          $('div[data-prerequisite="bulk_jwks_url_auth"]').hide();
        }
      }
    });

    $('#PrerequisitesModal .prerequisites-forms > .form-group').each(function(){
      var requiredby = $(this).data('requiredby');
      var definedby = $(this).data('definedby');
      var prerequisite = $(this).data('prerequisite');

      var definedList = [];
      var show = false;
      if(definedby){
        definedby.split(',').forEach(function(item){
          definedList.push(item);
        })
      }
      if(requiredby){
        requiredby.split(',').forEach(function(item){
          if(sequences.includes(item)){
            // this field is required by one of the sequences I'm running
            // is it also defined by one of the sequences?
            var alreadyDefined = false;
            definedList.forEach(function(defined){
              let beforeSequenceThatRequires = false;
              sequences.forEach(function(seq){
                beforeSequenceThatRequires = beforeSequenceThatRequires || (seq == item);
                if(!beforeSequenceThatRequires){
                  if(defined === seq){
                    alreadyDefined = true;
                  }
                }
              })
            })
            if(!alreadyDefined){
              show = true;
              requirements.push(prerequisite)
            }
          }
        })
      }

      if(show){
        let formInput = $(this).clone();
        formInput.find('[data-toggle="tooltip"]').tooltip()
        if(variable_defaults[prerequisite] !== undefined){

          if(formInput.find('input[type=radio]').length) {
            formInput.find('input[type=radio]').each(function(_index, checkBox) {
              $(checkBox)[0].checked =  $(checkBox).val() == variable_defaults[prerequisite].toString()
            });

          } else {
            if(formInput.find('input').val() == ''){
              formInput.find('input').val(variable_defaults[prerequisite]);
            }
          }
        }
        if(lockedVariables.includes(prerequisite)){
          formInput.find('input').attr('readonly', 'readonly');
          formInput.find(':radio:not(:checked)').attr('disabled', true);
          
          $('.disabled-prerequisites').append(formInput);
          $('.disabled-prerequisite-group-title').show();
          $('.disabled-prerequisites').show();
          formInput.find(':radio').each(function(){
            $(this).attr('id', $(this)[0].id + '_active');
          });
        } else {
          formInput.find(':radio').each(function(){
            $(this).attr('id', $(this)[0].id + '_active');
          });
        if(formInput.find('input').length >0){
          formInput.find('input')[0].removeAttribute('readonly');
        }
        formInput.find(':radio:not(:checked)').attr('disabled', false);
        $('.enabled-prerequisites').append(formInput);
        $('.enabled-prerequisite-group-title').show();
        $('.enabled-prerequisites').show();
        }
        //$(this).show()
      } else {
        //$(this).hide();
      }


      
    });

    $('#PrerequisitesModal input[name=sequence]').val(sequences.join(','));
    $('#PrerequisitesModal input[name=test_case]').val(test_cases.join(','));
    $('#PrerequisitesModal input[name=required_fields]').val(requirements.join(','));

    // Confidential client special case
    
    if($('#confidential_client_on_active').is(':checked')){
       $('div[data-prerequisite="client_secret"]').show();
    } else {
       $('div[data-prerequisite="client_secret"]').hide();
    }

    if($('#onc_sl_confidential_client_on_active').is(':checked')){
       $('div[data-prerequisite="onc_sl_client_secret"]').show();
    } else {
       $('div[data-prerequisite="onc_sl_client_secret"]').hide();
    }
    

    if(requirements.length === 0){
      $('#PrerequisitesModal form').submit();
    } else {
      $('#PrerequisitesModal').modal('show');
    }

    if(popupTitle){
      $('#PrerequisitesModalTitle').html(popupTitle)
    }

    if(show_uris){
      $('.show-uris').show();
    }

    if(show_bulk_registration_info){
      $('.show-bulk-registration-info').show();
    }
  })


  $('.disable-buttons').each(function(){
    $(this).find('.btn').attr('disabled', true)

    $(this).attr('title', $(this).data('preconditionDescription'))
                        .attr('data-toggle','tooltip');
  });

  $('.test-results-more').on('click', function() {
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

  $('.log-request-more').on('click', function() {
    if($(this).data('testingInstanceId') && $(this).data('requestId')){
      var url = window.basePath + '/' + $(this).data('testingInstanceId') + '/test_request/' + $(this).data('requestId');
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
  
  $('.test-list .test-list-more').on('click', function() {
    if($(this).data('sequenceName') && $(this).data('testIndex') !== undefined){
      var url = window.basePath + '/test_details/' + $(this).data('module') + '/' + $(this).data('sequenceName') + '/' + $(this).data('testIndex');
      $("#testDetailsModal").find('.modal-content').load(url, function(value){
        $("#testDetailsModal").modal('show');
      })
    }
  })

  $(":input[type=text][readonly='readonly']").on('click', function(){
    this.select();
  })

  $("textarea[readonly='readonly']").on('click', function(){
    this.select();
  })

  if(window.location.hash.length > 0){
    let hashParts = window.location.hash.split('#')[1].split('/');
    let testCasePart = hashParts[0];

    if(hashParts.length > 1) {
      testCasePart = hashParts[1];
      $('#group-link-' + hashParts[0]).tab('show');
    }

    if(testCasePart.length > 0){
      testCasePart.split(',').forEach(function(tc){
        var testCase = $('[data-test-case='+tc+']');
        var details = $('#' + tc + '-details');
        details.collapse('show')
        testCase.find('.sequence-expand-button').text('Hide Details')
      })
    }
  }

  $('[data-toggle="tooltip"]').tooltip()

  $('#WaitModal').modal('show');

  var autoRun = $.getQueryParameters().autoRun;
  if(autoRun) {
    var url = window.location.pathname;
    window.history.replaceState({}, null, url);
    $("button[data-sequence='" + autoRun + "']").click()
  }

  // Create a handler to handle the animation of the logo
  function handleScroll(_) {
    /* remove the animation duration if we are loaded to the middle of the page because it is distracting */
    /* using set timeout to reset it so when the user scrolls transitions are enabled. */
    if(_ === null){
      $('.server-info img, .server-name').addClass('no-transition')
      setTimeout(function(){$('.server-info img, .server-name').removeClass('no-transition')}, 500);
    }
    if($(window).scrollTop() > 80) {
      $('.server-info').addClass('show-logo')
    }
    else {
      $('.server-info').removeClass('show-logo')
    }
  }
  // Need to call it for when we initially load
  handleScroll(null)
  // Then register the handler
  $(window).on('scroll', handleScroll)

  function handlePresetChange(e, preset_id = ""){
    preset_id = preset_id == "" ? $('#preset-select option:selected').data('selected') : preset_id;
    var all = $('#preset-select option:selected').data('all');
    var modules = $('#preset-select option:selected').data('module_names').split(",");
    var preset = all[preset_id] == undefined ? "" : all[preset_id];
    
    if (preset !== "") {
      document.getElementById("preset-select").selectedIndex = Object.keys(all).indexOf(preset_id) + 1;
    }

    $el = $('input[name=fhir_server]');
    $el.val(preset.uri);
    $el.prop('readonly', preset !== '');
    var preset_on = $el.val() == '' ? false : true;

    if (preset_on) {
      modules.forEach(function(mod){$(document.getElementById(mod)).attr('disabled', true);});
      presetCheck = document.getElementById(preset.module);
      if(presetCheck){
        $(presetCheck).prop("checked", true).attr("disabled", false);
      }

      document.getElementById("preset").value = JSON.stringify(preset);
      document.getElementById("instructions-link").style.display = preset.instructions == null ? "none" : "";
      document.getElementById("instructions-link").href = preset.instructions;

    } else {
      modules.forEach(function(mod){$(document.getElementById(mod)).attr('disabled', false)});
      document.getElementById("preset").value = "";
      document.getElementById("instructions-link").style.display = "none";
    }
  }

  // Call when we initially load
  if($('#preset-select').length > 0){
    handlePresetChange();
  }

  // Set handler
  $('#preset-select').on('change', handlePresetChange);

  $(document.getElementsByClassName("next-back")).on('click', function() {
    var next_tab = $('#' + this.id).data('next_tab');
    $('#group-link-' + next_tab).click();
  });

  if (window.location.hash != "") {
    var preset_id = window.location.hash;
    if (preset_id.startsWith("#preset-")) {
      preset_id = preset_id.substring('#preset-'.length);
      $('#preset-select').trigger("change", preset_id);
    }
  }
}); 
