# frozen_string_literal: true

require_relative '../../../../test/test_helper'
require 'json'

describe Inferno::Sequence::SmartSchedulingLinksBasicSequence do
  before do
    @sequence_class = Inferno::Sequence::SmartSchedulingLinksBasicSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'

    @manifest_url = 'http://www.example.com/$bulk-manifest'
    @location = 'http://www.example.com/locations.ndjson'
    @locations = [@location]
    @schedule = 'http://www.example.com/schedules.ndjson'
    @schedules = [@schedule]
    @slot = 'http://www.example.com/slots.ndjson'
    @slots = [@slot]

    @instance = Inferno::TestingInstance.create(url: @base_url, token: @token, selected_module: 'ips')

    @client = FHIR::Client.for_testing_instance(@instance)

    @sample_manifest_file_string = '{
      "transactionTime" : "2021-03-10T18:16:34.535Z",
      "request" : "http://www.example.com/$bulk-publish",
      "output" : [
        {
          "type": "Location",
          "url": "http://www.example.com/locations.ndjson"
        },
        {
          "type": "Schedule",
          "url": "http://www.example.com/schedules.ndjson"
        },
        {
          "type": "Slot",
          "url": "http://www.example.com/slots.ndjson",
          "extension": {
            "state": [
              "MA"
            ]
          }
        }
      ]
    }'

    @sample_manifest_file = JSON.parse(@sample_manifest_file_string)

    # @composition_resource = FHIR.from_contents(load_fixture(:composition))
    # @document_response = FHIR.from_contents(load_fixture(:document_response))
  end

  # 01
  describe 'manifest url is valid tests' do
    before do
      @manifest_url_form_test = @sequence_class[:manifest_url_form]
    end

    it 'fails when url does not end in /$bulk-publish' do
      instance_copy = @instance.clone
      instance_copy.manifest_url = 'http://sample-url/invalid'
      sequence = @sequence_class.new(instance_copy, @client)

      error = assert_raises(Inferno::AssertionException) do
        sequence.run_test(@manifest_url_form_test)
      end

      assert_match('Manifest file must end in $bulk-publish', error.message)
    end

    it 'fails when manifest_url is not a url' do
      instance_copy = @instance.clone
      instance_copy.manifest_url = '$bulk-publish'
      sequence = @sequence_class.new(instance_copy, @client)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(@manifest_url_form_test)
      end

      # assert_match("Manifest file must end in $bulk-publish", error.message)
    end

    # it 'fails when manifest_url is empty' do
    #   instance_copy = @instance.clone
    #   instance_copy.manifest_url = ""
    #   @sequence = @sequence_class.new(instance_copy, @client)

    #   error = assert_raises(Inferno::AssertionException) do
    #     @sequence.run_test(@test)
    #   end

    # end

    it 'succeeds when url ends is $bulk-publish' do
      instance_copy = @instance.clone
      instance_copy.manifest_url = 'http://test.gov/$bulk-publish'
      sequence = @sequence_class.new(instance_copy, @client)
      assert_raises(Inferno::PassException) do
        sequence.run_test(@manifest_url_form_test)
      end
    end
  end

  # 02
  describe 'manifest file is valid json' do
    before do
      @manifest_downloadable_test = @sequence_class[:manifest_downloadable]
    end

    it 'fails when manifest file is not valid json' do
      invalid_json = 'invalid_json'
      stub_request(:get, @manifest_url)
        .to_return(status: 200, body: invalid_json, headers: {})

      instance_copy = @instance.clone
      instance_copy.manifest_url = @manifest_url
      sequence = @sequence_class.new(instance_copy, @client)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(@manifest_downloadable_test)
      end
    end

    it 'fails when manifest url is not a valid uri ' do
      invalid_uri = 'invalid_uri'
      stub_request(:get, invalid_uri)
        .to_return(status: 200, body: '', headers: {})

      instance_copy = @instance.clone
      instance_copy.manifest_url = invalid_uri
      sequence = @sequence_class.new(instance_copy, @client)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(@manifest_downloadable_test)
      end
    end

    it 'succeeds when manfest file is valid json' do
      valid_json = '{"test" : "test"}'
      stub_request(:get, @manifest_url)
        .to_return(status: 200, body: valid_json, headers: {})

      instance_copy = @instance.clone
      instance_copy.manifest_url = @manifest_url
      sequence = @sequence_class.new(instance_copy, @client)

      sequence.run_test(@manifest_downloadable_test)
    end
  end

  # 03
  describe 'manifest is structured properly' do
    before do
      @manifest_minimum_requirement_test = @sequence_class[:manifest_minimum_requirement]
    end

    it 'succeeds with manifest file containing each required field' do
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      assert_raises(Inferno::PassException) do
        sequence.run_test(@manifest_minimum_requirement_test)
      end
    end

    it 'fails when missing transactionTime' do
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)

      sample_manifest_file_missing_transaction_time = JSON.parse('{
        "request" : "http://www.example.com/$bulk-publish",
        "output" : [
          {
            "type": "Location",
            "url": "http://www.example.com/locations.ndjson"
          },
          {
            "type": "Schedule",
            "url": "http://www.example.com/schedules.ndjson"
          },
          {
            "type": "Slot",
            "url": "http://www.example.com/slots-2021-W09.ndjson",
            "extension": {
              "state": [
                "MA"
              ]
            }
          }
        ]
      }')

      sequence.instance_variable_set(:@manifest, sample_manifest_file_missing_transaction_time)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(@manifest_minimum_requirement_test)
      end
    end

    it 'fails when missing request' do
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)

      sample_manifest_file_missing_request = JSON.parse('{
        "transactionTime" : "2021-03-10T18:16:34.535Z",
        "output" : [
          {
            "type": "Location",
            "url": "http://www.example.com/locations.ndjson"
          },
          {
            "type": "Schedule",
            "url": "http://www.example.com/schedules.ndjson"
          },
          {
            "type": "Slot",
            "url": "http://www.example.com/slots-2021-W09.ndjson",
            "extension": {
              "state": [
                "MA"
              ]
            }
          }
        ]
      }')

      sequence.instance_variable_set(:@manifest, sample_manifest_file_missing_request)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(@manifest_minimum_requirement_test)
      end
    end

    it 'fails when missing output' do
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)

      sample_manifest_file_missing_output = JSON.parse('{
        "transactionTime" : "2021-03-10T18:16:34.535Z",
        "request" : "http://www.example.com/$bulk-publish"
      }')

      sequence.instance_variable_set(:@manifest, sample_manifest_file_missing_output)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(@manifest_minimum_requirement_test)
      end
    end
  end

  # 04
  describe 'manifest is structured properly' do
    before do
      @manifest_contains_jurisdictions_test = @sequence_class[:manifest_contains_jurisdictions]
    end

    it 'succeeds with manifest file containing each required field' do
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.run_test(@manifest_contains_jurisdictions_test)
    end

    it 'fails when state is not an array' do
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)

      sample_manifest_file_state_not_array = JSON.parse('{
        "request" : "http://www.example.com/$bulk-publish",
        "output" : [
          {
            "type": "Location",
            "url": "http://www.example.com/locations.ndjson"
          },
          {
            "type": "Schedule",
            "url": "http://www.example.com/schedules.ndjson"
          },
          {
            "type": "Slot",
            "url": "http://www.example.com/slots-2021-W09.ndjson",
            "extension": {
              "state" : "MA"
            }
          }
        ]
      }')

      sequence.instance_variable_set(:@manifest, sample_manifest_file_state_not_array)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(@manifest_contains_jurisdictions_test)
      end
    end

    it 'fails when state is not a 2 letter abbreviations' do
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)

      sample_manifest_file_state_not_2_letters = JSON.parse('{
        "request" : "http://www.example.com/$bulk-publish",
        "output" : [
          {
            "type": "Location",
            "url": "http://www.example.com/locations.ndjson"
          },
          {
            "type": "Schedule",
            "url": "http://www.example.com/schedules.ndjson"
          },
          {
            "type": "Slot",
            "url": "http://www.example.com/slots-2021-W09.ndjson",
            "extension": {
              "state" : "MAA"
            }
          }
        ]
      }')

      sequence.instance_variable_set(:@manifest, sample_manifest_file_state_not_2_letters)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(@manifest_contains_jurisdictions_test)
      end
    end
  end

  # 05
  describe 'manifest with since parameter tests' do
    before do
      @manifest_since_test = @sequence_class[:manifest_since]
    end

    it 'omits if since is not provided' do
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)

      assert_raises(Inferno::OmitException) do
        sequence.run_test(@manifest_since_test)
      end
    end

    it 'omits if since is blank' do
      instance_copy = @instance.clone
      instance_copy.manifest_since = ''
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)

      assert_raises(Inferno::OmitException) do
        sequence.run_test(@manifest_since_test)
      end
    end

    it 'error if since is not a date' do
      instance_copy = @instance.clone
      instance_copy.manifest_since = 'not a date'
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(@manifest_since_test)
      end
    end

    it 'skips if manifest is blank' do
      instance_copy = @instance.clone
      instance_copy.manifest_since = '2021-04-02'
      sequence = @sequence_class.new(instance_copy, @client)

      assert_raises(Inferno::SkipException) do
        sequence.run_test(@manifest_since_test)
      end
    end

    # TODO: shouldn't this still be a pass because since is allowed to not be implemented
    it 'fails when since parameter is provided but since response is the same' do
      instance_copy = @instance.clone
      instance_copy.manifest_since = '2021-04-02'
      instance_copy.manifest_url = @manifest_url
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)

      manifest_since_url = @manifest_url + '?_since=2021-04-02'
      stub_request(:get, manifest_since_url)
        .to_return(status: 200, body: @sample_manifest_file_string, headers: {})

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(@manifest_since_test)
      end
    end

    it 'fails when manifest response has error' do
      instance_copy = @instance.clone
      instance_copy.manifest_since = '2021-04-02'
      instance_copy.manifest_url = @manifest_url
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)

      manifest_since_url = @manifest_url + '?_since=2021-04-02'
      stub_request(:get, manifest_since_url)
        .to_return(status: 500, body: @sample_manifest_file_string, headers: {})

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(@manifest_since_test)
      end
    end

    it 'succeeds when since parameter is provided with correct params' do
      instance_copy = @instance.clone
      instance_copy.manifest_since = '2021-04-02'
      instance_copy.manifest_url = @manifest_url
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)

      manifest_since = '{
        "transactionTime" : "2021-03-10T18:16:34.535Z",
        "request" : "http://www.example.com/$bulk-publish",
        "output" : [
          {
            "type": "Schedule",
            "url": "http://www.example.com/schedules.ndjson"
          },
          {
            "type": "Slot",
            "url": "http://www.example.com/slots.ndjson",
            "extension": {
              "state": [
                "MA"
              ]
            }
          }
        ]
      }'

      # sorted output urls will be "http://www.example.com/schedules.ndjson", "http://www.example.com/slots.ndjson"
      manifest_since_url = @manifest_url + '?_since=2021-04-02'
      stub_request(:get, manifest_since_url)
        .to_return(status: 200, body: manifest_since, headers: {})

      assert_raises(Inferno::PassException) do
        sequence.run_test(@manifest_since_test)
      end
    end

    it 'fails when since parameter is not implement correctly' do
    end
  end

  #
  #   #8
  #   describe 'location resources contain valid FHIR resources' do
  #     before do
  #       @location_valid_test = @sequence_class[:location_valid]
  #     end
  #     it 'succeeds when location has valid FHIR resources' do
  #       instance_copy = @instance.clone
  #       sequence = @sequence_class.new(instance_copy, @client)
  #       sequence.instance_variable_set(:@manifest, @sample_manifest_file);
  #       sequence.instance_variable_set(:@location_urls, @locations);
  #
  #
  #       body = '{"resourceType":"Location","id":"0", "name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}'
  #
  #
  #       stub_request(:get, @location)
  #         .to_return(status: 200, body: body, headers: {})
  #       pass_exception = assert_raises(Inferno::PassException) do
  #         sequence.run_test(@location_valid_test)
  #       end
  #
  #     end
  #   end
  #
  #   #9, 10, 11, 12
  #   describe 'location contains optional VTRcks PIN, district, description, position tests all pass with correct data' do
  #     before do
  #       #run the :location_valid test in preparation for the tests after
  #       @location_valid_test = @sequence_class[:location_valid]
  #       instance_copy = @instance.clone
  #       @sequence = @sequence_class.new(instance_copy, @client)
  #       @sequence.instance_variable_set(:@manifest, @sample_manifest_file);
  #       @sequence.instance_variable_set(:@location_urls, @locations);
  #
  #       body = '{"resourceType":"Location","id":"0","name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}
  #               {"resourceType":"Location","id":"0","name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}
  #               {"resourceType":"Location","id":"0","name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}
  #               {"resourceType":"Location","id":"0","name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}
  #               {"resourceType":"Location","id":"0","name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}'
  #
  #       stub_request(:get, @location).to_return(status: 200, body: body, headers: {})
  #       @sequence.run_test(@location_valid_test)
  #
  #
  #     end
  #
  #     it 'succeeds when location has VTRcks PIN' do
  #       @test = @sequence_class[:location_optional_vtrcks_pin]
  #
  #       @sequence = @sequence_class.new(instance_copy, @client)
  #
  #       assert_raises(Inferno::PassException) do
  #         @sequence.run_test(@test)
  #       end
  #     end
  #
  #     it 'succeeds when location contains option district' do
  #       @test = @sequence_class[:location_optional_district]
  #
  #       @sequence = @sequence_class.new(instance_copy, @client)
  #
  #       assert_raises(Inferno::PassException) do
  #         @sequence.run_test(@test)
  #       end
  #     end
  #
  #     it 'succeeds when location contains option description' do
  #       @test = @sequence_class[:location_optional_description]
  #
  #       @sequence = @sequence_class.new(instance_copy, @client)
  #
  #       assert_raises(Inferno::PassException) do
  #         @sequence.run_test(@test)
  #       end
  #     end
  #
  #     it 'succeeds when location contains option position' do
  #       @test = @sequence_class[:location_optional_position]
  #
  #       @sequence = @sequence_class.new(instance_copy, @client)
  #
  #       assert_raises(Inferno::PassException) do
  #         @sequence.run_test(@test)
  #       end
  #     end
  #   end

  #   #9, 10, 11, 12
  #   describe 'location contains optional VTRcks PIN, district, description, position tests all fail with correct error counts' do
  #     before do
  #       #run the :location_valid test in preparation for the tests after
  #       @location_valid_test = @sequence_class[:location_valid]
  #       instance_copy = @instance.clone
  #       @sequence = @sequence_class.new(instance_copy, @client)
  #       @sequence.instance_variable_set(:@manifest, @sample_manifest_file);
  #       @sequence.instance_variable_set(:@location_urls, @locations);
  #
  #       body = '{"resourceType":"Location","id":"0","name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}
  #               {"resourceType":"Location","id":"0","name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}
  #               {"resourceType":"Location","id":"0","name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}
  #               {"resourceType":"Location","id":"0","name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}
  #               {"resourceType":"Location","id":"0","name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}'
  #
  #       stub_request(:get, @location).to_return(status: 200, body: body, headers: {})
  #       @sequence.run_test(@location_valid_test)
  #
  #
  #     end
  #
  #     it 'succeeds when location has VTRcks PIN' do
  #       @test = @sequence_class[:location_optional_vtrcks_pin]
  #
  #       @sequence = @sequence_class.new(instance_copy, @client)
  #
  #       assert_raises(Inferno::PassException) do
  #         @sequence.run_test(@test)
  #       end
  #     end
  #
  #     it 'succeeds when location contains option district' do
  #       @test = @sequence_class[:location_optional_district]
  #
  #       @sequence = @sequence_class.new(instance_copy, @client)
  #
  #       assert_raises(Inferno::PassException) do
  #         @sequence.run_test(@test)
  #       end
  #     end
  #
  #     it 'succeeds when location contains option description' do
  #       @test = @sequence_class[:location_optional_description]
  #
  #       @sequence = @sequence_class.new(instance_copy, @client)
  #
  #       assert_raises(Inferno::PassException) do
  #         @sequence.run_test(@test)
  #       end
  #     end
  #
  #     it 'succeeds when location contains option position' do
  #       @test = @sequence_class[:location_optional_position]
  #
  #       @sequence = @sequence_class.new(instance_copy, @client)
  #
  #       assert_raises(Inferno::PassException) do
  #         @sequence.run_test(@test)
  #       end
  #     end
  #
  #
  #   end

  # 13
  describe 'schedule is valid' do
    it 'succeeds with valid schedules' do
      schedule_valid_test = @sequence_class[:schedule_valid]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@schedule_urls, @schedules)
      sequence.instance_variable_set(:@location_reference_ids, ['Location/0', 'Location/1', 'Location/2', 'Location/3'])

      body = '{"resourceType":"Schedule","id":"10","serviceType":[{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/service-type","code":"57","display":"Immunization"},{"system":"http://fhir-registry.smarthealthit.org/CodeSystem/service-type","code":"covid19-immunization","display":"COVID-19 Immunization Appointment"}]}],"actor":[{"reference":"Location/0"}]}
              {"resourceType":"Schedule","id":"11","serviceType":[{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/service-type","code":"57","display":"Immunization"},{"system":"http://fhir-registry.smarthealthit.org/CodeSystem/service-type","code":"covid19-immunization","display":"COVID-19 Immunization Appointment"}]}],"actor":[{"reference":"Location/1"}]}
              {"resourceType":"Schedule","id":"12","serviceType":[{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/service-type","code":"57","display":"Immunization"},{"system":"http://fhir-registry.smarthealthit.org/CodeSystem/service-type","code":"covid19-immunization","display":"COVID-19 Immunization Appointment"}]}],"actor":[{"reference":"Location/2"}]}
              {"resourceType":"Schedule","id":"13","serviceType":[{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/service-type","code":"57","display":"Immunization"},{"system":"http://fhir-registry.smarthealthit.org/CodeSystem/service-type","code":"covid19-immunization","display":"COVID-19 Immunization Appointment"}]}],"actor":[{"reference":"Location/3"}]}'

      stub_request(:get, @schedule).to_return(status: 200, body: body, headers: {})

      sequence.run_test(schedule_valid_test)
    end
  end

  # 14
  describe 'schedule has valid reference fields test' do
    it 'succeeds with valid data' do
      # run the :location_valid test in preparation for the tests after
      schedule_valid_reference_fields_test = @sequence_class[:schedule_valid_reference_fields]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@schedule_urls, @schedules)
      sequence.instance_variable_set(:@schedule_reference_ids, ['Schedule/10', 'Schedule/11', 'Schedule/12', 'Schedule/13'])
      sequence.instance_variable_set(:@unknown_location_reference_count, ['Location/0', 'Location/1', 'Location/2', 'Location/3'])

      sequence.run_test(schedule_valid_reference_fields_test)
    end
  end

  # 15
  describe 'schedule correct service type tests' do
    it 'succeeds when schedule has no invalid service types' do
      # run the :location_valid test in preparation for the tests after
      schedule_correct_service_type_test = @sequence_class[:schedule_correct_service_type]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@schedule_urls, @schedules)
      sequence.instance_variable_set(:@schedule_reference_ids, ['Schedule/10', 'Schedule/11', 'Schedule/12', 'Schedule/13'])
      sequence.instance_variable_set(:@invalid_service_type_count, 0)

      sequence.run_test(schedule_correct_service_type_test)
    end

    it 'fails when schedule has invalid service types' do
      # run the :location_valid test in preparation for the tests after
      schedule_correct_service_type_test = @sequence_class[:schedule_correct_service_type]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@schedule_urls, @schedules)
      sequence.instance_variable_set(:@schedule_reference_ids, ['Schedule/10', 'Schedule/11', 'Schedule/12', 'Schedule/13'])
      sequence.instance_variable_set(:@invalid_service_type_count, 3)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(schedule_correct_service_type_test)
      end
    end
  end

  # 16
  describe 'schedule has vaccine product info tests' do
    it 'succeeds when schedule has no invalid vaccine products' do
      # run the :location_valid test in preparation for the tests after
      schedule_optional_vaccine_product_extension_test = @sequence_class[:schedule_optional_vaccine_product_extension]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@schedule_urls, @schedules)
      sequence.instance_variable_set(:@schedule_reference_ids, ['Schedule/10', 'Schedule/11', 'Schedule/12', 'Schedule/13'])
      sequence.instance_variable_set(:@invalid_vaccine_product_count, 0)

      sequence.run_test(schedule_optional_vaccine_product_extension_test)
    end

    it 'fails when schedule has invalid vaccine products' do
      # run the :location_valid test in preparation for the tests after
      schedule_optional_vaccine_product_extension_test = @sequence_class[:schedule_optional_vaccine_product_extension]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@schedule_urls, @schedules)
      sequence.instance_variable_set(:@schedule_reference_ids, ['Schedule/10', 'Schedule/11', 'Schedule/12', 'Schedule/13'])
      sequence.instance_variable_set(:@invalid_vaccine_product_count, 1)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(schedule_optional_vaccine_product_extension_test)
      end
    end
  end

  # 17
  describe 'schedule has optional vaccine dose number test' do
    it 'succeeds when there are no invalid vaccine dose number' do
      schedule_optional_vaccine_dose_number_test = @sequence_class[:schedule_optional_vaccine_dose_number]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@schedule_urls, @schedules)
      sequence.instance_variable_set(:@schedule_reference_ids, ['Schedule/10', 'Schedule/11', 'Schedule/12', 'Schedule/13'])
      sequence.instance_variable_set(:@invalid_vaccine_dose_number_count, 0)

      sequence.run_test(schedule_optional_vaccine_dose_number_test)
    end

    it 'fails when schedule has invalid vaccine dose numbers' do
      schedule_optional_vaccine_dose_number_test = @sequence_class[:schedule_optional_vaccine_dose_number]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@schedule_urls, @schedules)
      sequence.instance_variable_set(:@schedule_reference_ids, ['Schedule/10', 'Schedule/11', 'Schedule/12', 'Schedule/13'])
      sequence.instance_variable_set(:@invalid_vaccine_dose_number_count, 2)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(schedule_optional_vaccine_dose_number_test)
      end
    end
  end

  # 18
  describe 'slot is valid test' do
    it 'succeeds when slot files contain valid FHIR resources' do
      slot_valid_test = @sequence_class[:slot_valid]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@slot_urls, @slots)
      sequence.instance_variable_set(:@schedule_reference_ids, ['Schedule/10', 'Schedule/11', 'Schedule/12', 'Schedule/13'])

      body = '{"resourceType":"Slot","id":"20","schedule":{"reference":"Schedule/10"},"status":"free","start":"2021-03-01T14:00:00.000Z","end":"2021-03-01T23:00:00.000Z","extension":[{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-deep-link","valueUrl":"https://ehr-portal.example.org/bookings?slot=1000000"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/slot-capacity","valueInteger":100}]}
              {"resourceType":"Slot","id":"21","schedule":{"reference":"Schedule/11"},"status":"free","start":"2021-03-01T14:00:00.000Z","end":"2021-03-01T23:00:00.000Z","extension":[{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-deep-link","valueUrl":"https://ehr-portal.example.org/bookings?slot=1000001"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/slot-capacity","valueInteger":100}]}
              {"resourceType":"Slot","id":"22","schedule":{"reference":"Schedule/12"},"status":"free","start":"2021-03-01T14:00:00.000Z","end":"2021-03-01T23:00:00.000Z","extension":[{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-deep-link","valueUrl":"https://ehr-portal.example.org/bookings?slot=1000002"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/slot-capacity","valueInteger":100}]}
              {"resourceType":"Slot","id":"23","schedule":{"reference":"Schedule/13"},"status":"free","start":"2021-03-01T14:00:00.000Z","end":"2021-03-01T23:00:00.000Z","extension":[{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-deep-link","valueUrl":"https://ehr-portal.example.org/bookings?slot=1000003"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/slot-capacity","valueInteger":100}]}'

      stub_request(:get, @slot).to_return(status: 200, body: body, headers: {})

      sequence.run_test(slot_valid_test)
    end

    it 'succeeds but counts unknown_schedule_reference, invalid_booking_link_count, invalid_booking_phone_count, and invalid capacity count correctly' do
      slot_valid_test = @sequence_class[:slot_valid]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@slot_urls, @slots)
      sequence.instance_variable_set(:@schedule_reference_ids, ['Schedule/10'])

      body = '{"resourceType":"Slot","id":"20","schedule":{"reference":"Schedule/10"},"status":"free","start":"2021-03-01T14:00:00.000Z","end":"2021-03-01T23:00:00.000Z","extension":[{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-deep-link","valueUrl":"https://ehr-portal.example.org/bookings?slot=1000000"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-phone","valueString":"test-string"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/slot-capacity","valueInteger":100}]}
        {"resourceType":"Slot","id":"21","schedule":{"reference":"Schedule/11"},"status":"free","start":"2021-03-01T14:00:00.000Z","end":"2021-03-01T23:00:00.000Z","extension":[{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-deep-link","valueUrl":"https://ehr-portal.example.org/bookings?slot=1000001"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-phone","valueString":"test-string"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/slot-capacity","valueInteger":100}]}
        {"resourceType":"Slot","id":"22","schedule":{"reference":"Schedule/10"},"status":"free","start":"2021-03-01T14:00:00.000Z","end":"2021-03-01T23:00:00.000Z","extension":null}
        {"resourceType":"Slot","id":"23","schedule":{"reference":"Schedule/10"},"status":"free","start":"2021-03-01T14:00:00.000Z","end":"2021-03-01T23:00:00.000Z","extension":[]}
        {"resourceType":"Slot","id":"25","schedule":{"reference":"Schedule/10"},"status":"free","start":"2021-03-01T14:00:00.000Z","end":"2021-03-01T23:00:00.000Z","extension":[{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-phone","valueString":"test-string"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/slot-capacity","valueInteger":100}]}
        {"resourceType":"Slot","id":"26","schedule":{"reference":"Schedule/10"},"status":"free","start":"2021-03-01T14:00:00.000Z","end":"2021-03-01T23:00:00.000Z","extension":[{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-deep-link"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-phone","valueString":"test-string"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/slot-capacity","valueInteger":100}]}
        {"resourceType":"Slot","id":"27","schedule":{"reference":"Schedule/10"},"status":"free","start":"2021-03-01T14:00:00.000Z","end":"2021-03-01T23:00:00.000Z","extension":[{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-deep-link","valueUrl":null},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-phone","valueString":"test-string"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/slot-capacity","valueInteger":100}]}
        {"resourceType":"Slot","id":"28","schedule":{"reference":"Schedule/10"},"status":"free","start":"2021-03-01T14:00:00.000Z","end":"2021-03-01T23:00:00.000Z","extension":[{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-deep-link","valueUrl":"https://ehr-portal.example.org/bookings?slot=1000000"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/slot-capacity","valueInteger":100}]}
        {"resourceType":"Slot","id":"29","schedule":{"reference":"Schedule/10"},"status":"free","start":"2021-03-01T14:00:00.000Z","end":"2021-03-01T23:00:00.000Z","extension":[{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-deep-link","valueUrl":"https://ehr-portal.example.org/bookings?slot=1000000"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-phone"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/slot-capacity","valueInteger":100}]}
        {"resourceType":"Slot","id":"30","schedule":{"reference":"Schedule/10"},"status":"free","start":"2021-03-01T14:00:00.000Z","end":"2021-03-01T23:00:00.000Z","extension":[{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-deep-link","valueUrl":"https://ehr-portal.example.org/bookings?slot=1000000"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-phone","valueString":null},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/slot-capacity","valueInteger":100}]}
        {"resourceType":"Slot","id":"31","schedule":{"reference":"Schedule/10"},"status":"free","start":"2021-03-01T14:00:00.000Z","end":"2021-03-01T23:00:00.000Z","extension":[{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-deep-link","valueUrl":"https://ehr-portal.example.org/bookings?slot=1000000"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-phone","valueString":"test-string"}]}
        {"resourceType":"Slot","id":"32","schedule":{"reference":"Schedule/10"},"status":"free","start":"2021-03-01T14:00:00.000Z","end":"2021-03-01T23:00:00.000Z","extension":[{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-deep-link","valueUrl":"https://ehr-portal.example.org/bookings?slot=1000000"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-phone","valueString":"test-string"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/slot-capacity"}]}
        {"resourceType":"Slot","id":"33","schedule":{"reference":"Schedule/10"},"status":"free","start":"2021-03-01T14:00:00.000Z","end":"2021-03-01T23:00:00.000Z","extension":[{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-deep-link","valueUrl":"https://ehr-portal.example.org/bookings?slot=1000000"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/booking-phone","valueString":"test-string"},{"url":"http://fhir-registry.smarthealthit.org/StructureDefinition/slot-capacity","valueInteger":null}]}'

      stub_request(:get, @slot).to_return(status: 200, body: body, headers: {})

      sequence.run_test(slot_valid_test)

      # check counts for invalid booking link, invalid booking phone, and invalid capacity
      assert_equal(sequence.instance_variable_get(:@unknown_schedule_reference_count), 1) # Slots 21
      assert_equal(sequence.instance_variable_get(:@invalid_booking_link_count), 5) # Slots 22 , 23, 25, 26, 27
      assert_equal(sequence.instance_variable_get(:@invalid_booking_phone_count), 5) # Slots 22 , 23, 28, 29, 30
      assert_equal(sequence.instance_variable_get(:@invalid_capacity_count), 5) # Slots 22 , 23, 31, 32, 33
    end
  end

  # 19
  describe 'slot valid reference fields test' do
    it 'succeeds when unknown_schedule_reference is nil' do
      slot_valid_reference_fields_test = @sequence_class[:slot_valid_reference_fields]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@slot_urls, @slots)
      sequence.instance_variable_set(:@slot_reference_ids, ['Slot/20', 'Slot/21', 'Slot/22', 'Slot/23'])

      sequence.run_test(slot_valid_reference_fields_test)
    end

    it 'succeeds when slot files contain valid FHIR resources' do
      slot_valid_reference_fields_test = @sequence_class[:slot_valid_reference_fields]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@slot_urls, @slots)
      sequence.instance_variable_set(:@slot_reference_ids, ['Slot/20', 'Slot/21', 'Slot/22', 'Slot/23'])
      sequence.instance_variable_set(:@unknown_schedule_reference, 3)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(slot_valid_reference_fields_test)
      end
    end
  end

  # 20
  describe 'slot optional booking link tests' do
    it 'succeeds when invalid booking link count is 0' do
      slot_optional_booking_link_test = @sequence_class[:slot_optional_booking_link]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@slot_urls, @slots)
      sequence.instance_variable_set(:@slot_reference_ids, ['Slot/20', 'Slot/21', 'Slot/22', 'Slot/23'])
      sequence.instance_variable_set(:@invalid_booking_link_count, 0)

      sequence.run_test(slot_optional_booking_link_test)
    end

    it 'fails when there are invalid booking links' do
      slot_optional_booking_link_test = @sequence_class[:slot_optional_booking_link]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@slot_urls, @slots)
      sequence.instance_variable_set(:@slot_reference_ids, ['Slot/20', 'Slot/21', 'Slot/22', 'Slot/23'])
      sequence.instance_variable_set(:@invalid_booking_link_count, 3)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(slot_optional_booking_link_test)
      end
    end
  end

  # 21
  describe 'slot optional booking phone tests' do
    it 'succeeds when invalid booking link count is 0' do
      slot_optional_booking_phone_test = @sequence_class[:slot_optional_booking_phone]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@slot_urls, @slots)
      sequence.instance_variable_set(:@slot_reference_ids, ['Slot/20', 'Slot/21', 'Slot/22', 'Slot/23'])
      sequence.instance_variable_set(:@invalid_booking_phone_count, 0)

      sequence.run_test(slot_optional_booking_phone_test)
    end

    it 'fails when there are invalid booking phones' do
      slot_optional_booking_phone_test = @sequence_class[:slot_optional_booking_phone]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@slot_urls, @slots)
      sequence.instance_variable_set(:@slot_reference_ids, ['Slot/20', 'Slot/21', 'Slot/22', 'Slot/23'])
      sequence.instance_variable_set(:@invalid_booking_phone_count, 3)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(slot_optional_booking_phone_test)
      end
    end
  end

  # 22
  describe 'slot optional capacity tests' do
    it 'succeeds when invalid booking capacity count is 0' do
      slot_optional_booking_capacity_test = @sequence_class[:slot_optional_booking_capacity]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@slot_urls, @slots)
      sequence.instance_variable_set(:@slot_reference_ids, ['Slot/20', 'Slot/21', 'Slot/22', 'Slot/23'])
      sequence.instance_variable_set(:@invalid_capacity_count, 0)

      sequence.run_test(slot_optional_booking_capacity_test)
    end

    it 'fails when there are invalid capacities' do
      slot_optional_booking_capacity_test = @sequence_class[:slot_optional_booking_capacity]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@slot_urls, @slots)
      sequence.instance_variable_set(:@slot_reference_ids, ['Slot/20', 'Slot/21', 'Slot/22', 'Slot/23'])
      sequence.instance_variable_set(:@invalid_capacity_count, 3)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(slot_optional_booking_capacity_test)
      end
    end
  end
end
