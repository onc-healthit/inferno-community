// Inferno class represents API use
class Inferno {
  test_set;
  preset;
  instance;
  module;
  id;

  constructor() {
    this.PREFIX = `${window.location.origin}/api/v1/`;
    self = this;

    // Gets all test sets
    getData(`${this.PREFIX}test_set`).then(function(test_set_json) {
      self.test_set = test_set_json;
    });

    // Gets all presets 
    getData(`${this.PREFIX}preset`).then(function(preset_json) {
      self.preset = preset_json;
    });
  }

  // Creates a new instance, gets module data
  async createInstance(json_body) {
    this.instance = await postData(`${this.PREFIX}instance`, json_body);
    this.id = this.instance.id;
    this.module = await getData(`${this.PREFIX}instance/${this.id}/module`);
  }

  async updateInstance() {
    this.instance = await getData(`${this.PREFIX}instance/${this.id}`);
  }

  async updateReport() {
    return await getData(`${this.PREFIX}instance/${this.id}/report`);
  }

  async getSequenceResult(group_id, sequence_id) {
    return await getData(`${this.PREFIX}instance/${this.id}/result/group/${group_id}/sequence/${sequence_id}`);
  }

  async getGroupResult(group_id) {
    return await getData(`${this.PREFIX}instance/${this.id}/result/group/${group_id}`);
  }

  async getHttpRequests(result_id) {
    return await getData(`${this.PREFIX}instance/${this.id}/result/${result_id}/request`);
  }
  
  // Executes test with a stream
  async executeWithStream(streamFunction, group_id, sequence_id = "") {
    // Determine if executing sequence or group
    var url;
    if (sequence_id == "") {
      url = `${this.PREFIX}instance/${this.id}/module/group/${group_id}/$execute_stream`;
    } else {
      url = `${this.PREFIX}instance/${this.id}/module/group/${group_id}/sequence/${sequence_id}/$execute_stream`;
    }
  
    const response = await fetch(url, { method: 'POST'});
    const exampleReader = can.ndjsonStream(response.body).getReader(); // Open stream
    let result;
    
    while (!result || !result.done) { // Loop until stream closes
      result = await exampleReader.read(); // result.value is one line of NDJSON data
      streamFunction(result, sequence_id); // Call inputted function
    }
  }
}

var inferno = new Inferno();

// Loads start page form for testing
function loadTestSet() {
  // Loads HTML for all test set options
  inferno.test_set.forEach(function(test_set) {
    fhir_version = test_set.fhir_version == undefined ? "" : ` (${test_set.fhir_version.toUpperCase()})`;
    var html = `<option id='${test_set.id}'>${test_set.name}${fhir_version}</option>`;
    $("#form-test-set").append(html);
  });

  // Loads HTML for all preset options
  inferno.preset.forEach(function(preset) {
    var html = `
      <input type="checkbox" class="form-check-input preset-option" id="${preset.id}" onclick="fillPreset('${preset.id}')">
      <label class="form-check-label" for="${preset.id}">${preset.name}</label>
    `;
    $("#presets").append(html);
  });
};

// Updates form when a preset is clicked
function fillPreset(check_id) {
  // Determine which preset was clicked by id
  selected = inferno.preset.find(preset => preset.id == check_id);

  // Complete forms 
  if (document.getElementById(check_id).checked) {
    // Fill form with preset info
    document.getElementById("form-fhir-server").value = selected.fhir_server,
    document.getElementById("form-client-id").value = selected.client_id,
    document.getElementById("form-client-secret").value = selected.client_secret
    document.getElementById(selected.test_set).selected = true;

    // Lock form options
    all_test_sets = document.getElementsByClassName("start-form");
    Array.prototype.forEach.call(all_test_sets, test_set => test_set.readOnly = true);
    document.getElementById("form-test-set").disabled = true;

    // Clear other preset buttons
    all_presets = document.getElementsByClassName("preset-option");
    Array.prototype.forEach.call(all_presets, preset => preset.checked = false);
    document.getElementById(check_id).checked = true;
  } else {
    // Button unchecked: clear form
    document.getElementById("form-fhir-server").value = "",
    document.getElementById("form-client-id").value = "",
    document.getElementById("form-client-secret").value = ""

    // Unlock all form options
    all_test_sets = document.getElementsByClassName("start-form");
    Array.prototype.forEach.call(all_test_sets, test_set => test_set.readOnly = false);
    document.getElementById("form-test-set").disabled = false;
  }
}

// Submits form and creates instance
async function submitForm() {
  // Get data from form
  var test_set = document.getElementById("form-test-set");
  var test_set_id = test_set.options[test_set.selectedIndex].id;

  // Body for post request
  var json_body = {
    "test_set": test_set_id,
    "fhir_server": document.getElementById("form-fhir-server").value,
    "client_id": document.getElementById("form-client-id").value,
    "client_secret": document.getElementById("form-client-secret").value
  }

  // Clear start page
  document.getElementById("start-testing").innerHTML = "";
  
  // Load testing page with new instance info
  await inferno.createInstance(json_body);
  loadInstance();
  loadModule();
};

function loadInstance() {
  document.getElementById("instance-module").innerHTML = `<b>FHIR Server: </b>${inferno.instance.fhir_uri}`;
  document.getElementById("instance").style.display = "";
};

async function updateInstance() {
  await inferno.updateInstance();
  document.getElementById("instance-state-content").innerHTML = JSON.stringify(inferno.instance, undefined, 2);
  $('#instance-state').modal('show');
}

async function updateReport() {
  report = await inferno.updateReport();
  document.getElementById("instance-report-content").innerHTML = JSON.stringify(report, undefined, 2);
  $('#instance-report').modal('show');
}

// Load available tests
function loadModule() {
  // Show module elements
  document.getElementById("module").style.display = "";
  module_title = `<h3>${inferno.module.name}</h3>`
  $("#module").append(module_title);
  addModuleGroup();
}

// Add card for each group
function addModuleGroup() {
  inferno.module.groups.forEach(function(group) {
    button = group.run? `<button type="button" class="btn btn-primary ml-3" onclick="runStreamTests('${group.id}')" style="float: right;">Run</button>` : ""; // Only add button to run if group is executable
    html_group = `
      <div class="group pt-3">
        <div class="card">
          <h5 class="card-header" id="module-group-title-${group.id}">${group.name}
            ${button}
            <button type="button" class="btn btn-outline-dark" id="module-${group.id}-results" onclick="loadGroupResult('${group.id}')" style="float: right;">Results</button>
          </h5>
          <ul class="list-group list-group-flush" id="module-${group.id}"></ul>
        </div>
      </div>
    `;
    $("#module").append(html_group);

    addModuleSequence(group);
  });
}

// Add section of card for each sequence
function addModuleSequence(group) {
  group.sequences.forEach(function(sequence) {
    button = sequence.run? `<button type="button" class="btn btn-primary ml-3" onclick="runStreamTests('${group.id}', '${sequence.id}')" style="float: right;">Run</button>` : ""; // Only add button to run if sequence is executable
    html_sequence = `
      <li class="list-group-item" id="module-${sequence.id}">${sequence.name}
        ${button}
        <button type="button" class="btn btn-outline-secondary ml-3" id="module-${sequence.id}-results" onclick="loadSequenceResult('${group.id}', '${sequence.id}')" style="float: right;">Not Run</button>
      </li>
    `;
    $(`#module-${group.id}`).append(html_sequence);
  });
}

async function runStreamTests(group_id, sequence_id = "") {
  initializeProgressBar();
  $('#loading').modal("show");

  await inferno.executeWithStream(stream, group_id, sequence_id);

  $('.modal').css('overflow-y', 'auto');
  $('#loading').modal("hide");
  $('#instance-result').modal("show");
}

// Function that is called for each stream returned
function stream(result, sequence_id) {
  if (!result.done) {
    continue_stream(result.value, sequence_id);
  }
}

function continue_stream(result, sequence_id) {
  if (result.type == "update") {
    // Tests are running
    updateProgressBar(result);
  } else {
    // Tests are done
    document.getElementById("instance-result-content").innerHTML = JSON.stringify(result, undefined, 2);
    sequence_id == "" ? updateModuleResult(result) : updateModuleResult([result]);
  }
}

// Updates the result status of sequences in the HTML
function updateModuleResult(results) {
  results.forEach(function(result) {
    element = document.getElementById(`module-${result.name}-results`);
    element.className = resultClass(result.status);

    // Add button to access HTTP Requests
    if (element.innerHTML == "Not Run") {
      html = `<button type="button" class="btn btn-outline-secondary" id="module-${result.name}-http" onclick="loadHTTPRequests('${result.id}')" style="float: right;">HTTP Requests</button>`
      $(`#module-${result.name}`).append(html);
    }

    element.innerHTML = result.status;
  });
}

function initializeProgressBar() {
  $('#loading-progress-description').html("");
  $('#loading-progress-bar').attr('aria-valuenow', 0).css('width', 0 + '%').html(`0%`);
}

// Same functionality as Inferno's progress bar
function updateProgressBar(progress) {
  var percent = Math.round((progress.group.group_count / progress.group.group_total) * 100);
  $('#loading-progress-description').html(`(${progress.sequence.sequence_count} of ${progress.sequence.sequence_total} ${progress.sequence.sequence_name} tests complete)`);
  $('#loading-progress-bar').attr('aria-valuenow', progress).css('width', percent + '%').html(`${percent}%`);
}

// Return class based on result status to change color of result button
function resultClass(result) {
  var class_color;
  switch (result) {
    case "pass":
      class_color = "btn btn-outline-success ml-3";
      break;
    case "fail": 
      class_color = "btn btn-outline-danger ml-3";
      break;
    default: 
      class_color = "btn btn-outline-secondary ml-3";
  } 
  return class_color;
}

async function loadGroupResult(group_id) {
  result = await inferno.getGroupResult(group_id);
  document.getElementById("instance-result-content").innerHTML = JSON.stringify(result, undefined, 2);
  $('#instance-result').modal('show');
}

async function loadSequenceResult(group_id, sequence_id) {
  result = await inferno.getSequenceResult(group_id, sequence_id);
  document.getElementById("instance-result-content").innerHTML = JSON.stringify(result, undefined, 2);
  
  $('#instance-result').modal('show');
}

async function loadHTTPRequests(result_id) {
  http = await inferno.getHttpRequests(result_id);
  document.getElementById("instance-http-content").innerHTML = JSON.stringify(http, undefined, 2);
  $('#instance-http').modal('show');
}

// API Requests using fetch
async function postData(url = '', data = {}) {
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return await response.json();
};

async function getData(url = '') {
  const response = await fetch(url);
  return await response.json();
};