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

    @instance = Inferno::TestingInstance.create(url: @base_url, token: @token, selected_module: 'ips')   
    

    @client = FHIR::Client.for_testing_instance(@instance)


    @sample_manifest_file = JSON.parse('{
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
          "url": "http://www.example.com/slots-2021-W09.ndjson",
          "extension": {
            "state": [
              "MA"
            ]
          }
        }
      ]

    
    }')

    # @composition_resource = FHIR.from_contents(load_fixture(:composition))
    # @document_response = FHIR.from_contents(load_fixture(:document_response))
  end


  #01
  describe 'manifest url is valid tests' do
    before do
      #@sequence = @sequence_class.new(@instance, @client)
      @test = @sequence_class[:manifest_url_form]
    end

    it 'fails when url does not end in /$bulk-publish' do
      instance_copy = @instance.clone
      instance_copy.manifest_url = 'http://sample-url/invalid'
      @sequence = @sequence_class.new(instance_copy, @client)

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      assert_match("Manifest file must end in $bulk-publish", error.message)

    end

    it 'fails when manifest_url is not a url' do
      instance_copy = @instance.clone
      instance_copy.manifest_url = '$bulk-publish'
      @sequence = @sequence_class.new(instance_copy, @client)

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      #assert_match("Manifest file must end in $bulk-publish", error.message)
    end

    it 'fails when manifest_url is empty' do
      instance_copy = @instance.clone
      instance_copy.manifest_url = ""
      @sequence = @sequence_class.new(instance_copy, @client)

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      #assert_match("Manifest file must end in $bulk-publish", error.message)
    end

    it 'succeeds when url ends is $bulk-publish' do
      instance_copy = @instance.clone
      instance_copy.manifest_url = 'http://test.gov/$bulk-publish'
      @sequence = @sequence_class.new(instance_copy, @client)

      @sequence.run_test(@test)

    end
  end

  #02
  describe 'manifest file is valid json' do
    before do
      @test = @sequence_class[:manifest_downloadable]
    end

    it 'fails when manifest file is not valid json' do
      invalid_json = 'invalid_json'
      stub_request(:get, @manifest_url)
        .to_return(status: 200, body: invalid_json, headers: {})

      instance_copy = @instance.clone
      instance_copy.manifest_url = @manifest_url 
      @sequence = @sequence_class.new(instance_copy, @client)

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end
    end

    it 'fails when manifest url is not a valid uri ' do
      invalid_uri = 'invalid_uri'
      stub_request(:get, invalid_uri)
        .to_return(status: 200, body: "", headers: {})

      instance_copy = @instance.clone
      instance_copy.manifest_url = invalid_uri
      @sequence = @sequence_class.new(instance_copy, @client)

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end
    end

    it 'succeeds when manfest file is valid json' do
      valid_json = '{"test" : "test"}'
      stub_request(:get, @manifest_url)
        .to_return(status: 200, body: valid_json, headers: {})

      instance_copy = @instance.clone
      instance_copy.manifest_url = @manifest_url 
      @sequence = @sequence_class.new(instance_copy, @client)

      @sequence.run_test(@test)
    end
  end

  #03
  describe 'manifest is structured properly' do
    before do
      @test = @sequence_class[:manifest_minimum_requirement]
    end

    it 'succeeds with manifest file containing each required field' do
      instance_copy = @instance.clone
      @sequence = @sequence_class.new(instance_copy, @client)
      @sequence.instance_variable_set(:@manifest, @sample_manifest_file);
      pass_exception = assert_raises(Inferno::PassException) do
        @sequence.run_test(@test)
      end
    end
    
    it 'fails when missing transactionTime' do
      instance_copy = @instance.clone
      @sequence = @sequence_class.new(instance_copy, @client)
      
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
      
      @sequence.instance_variable_set(:@manifest, sample_manifest_file_missing_transaction_time);

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end
    end
  

  
    it 'fails when missing request' do
      instance_copy = @instance.clone
      @sequence = @sequence_class.new(instance_copy, @client)
      
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
      
      @sequence.instance_variable_set(:@manifest, sample_manifest_file_missing_request);

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end
    end

    it 'fails when missing output' do
      instance_copy = @instance.clone
      @sequence = @sequence_class.new(instance_copy, @client)
      
      sample_manifest_file_missing_output = JSON.parse('{
        "transactionTime" : "2021-03-10T18:16:34.535Z",
        "request" : "http://www.example.com/$bulk-publish"  
      }')
      
      @sequence.instance_variable_set(:@manifest, sample_manifest_file_missing_output);

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end
    end

    
  end

  #04
  describe 'manifest is structured properly' do
    before do
      @test = @sequence_class[:manifest_contains_jurisdictions]
    end

    it 'succeeds with manifest file containing each required field' do
      instance_copy = @instance.clone
      @sequence = @sequence_class.new(instance_copy, @client)
      @sequence.instance_variable_set(:@manifest, @sample_manifest_file);
      @sequence.run_test(@test)
    end
    
    it 'fails when state is not an array' do
      instance_copy = @instance.clone
      @sequence = @sequence_class.new(instance_copy, @client)
      
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
      
      @sequence.instance_variable_set(:@manifest, sample_manifest_file_state_not_array);

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end
    end

    it 'fails when state is not a 2 letter abbreviations' do
      instance_copy = @instance.clone
      @sequence = @sequence_class.new(instance_copy, @client)
      
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
      
      @sequence.instance_variable_set(:@manifest, sample_manifest_file_state_not_2_letters);

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end
    end
  end

  #05 - 07
  describe 'manifest with since parameter tests' do
    before do
      @test = @sequence_class[:manifest_downloadable]
    end

    it 'succeeds when since parameter is ignored' do

      
    end

    it 'succeeds when since parameter is implemented correctly' do

    end

    it 'fails when since parameter is not implement correctly' do
    end
  end

  #10
  describe 'location resources contain valid FHIR resources' do
    before do
      @test = @sequence_class[:location_valid]
    end
    it 'succeeds when location has valid FHIR resources' do
      instance_copy = @instance.clone
      @sequence = @sequence_class.new(instance_copy, @client)
      @sequence.instance_variable_set(:@manifest, @sample_manifest_file);
      @sequence.instance_variable_set(:@location_urls, @locations);


      body = '{"resourceType":"Location","id":"0","name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}'


      stub_request(:get, @location)
        .to_return(status: 200, body: body, headers: {})
      pass_exception = assert_raises(Inferno::PassException) do
        @sequence.run_test(@test)
      end




    end
  end

  describe 'location resources contain valid FHIR resources' do
    before do
      @test = @sequence_class[:location_valid]
    end
    it 'sets the appropriate instance variables' do
      instance_copy = @instance.clone
      @sequence = @sequence_class.new(instance_copy, @client)
      @sequence.instance_variable_set(:@manifest, @sample_manifest_file);
      @sequence.instance_variable_set(:@location_urls, @locations);


      body = '{"resourceType":"Location","id":"0","name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}]}
              {"resourceType":"Location","id":"0","name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}
              {"resourceType":"Location","name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}'


      stub_request(:get, @location)
        .to_return(status: 200, body: body, headers: {})
      pass_exception = assert_raises(Inferno::PassException) do
        @sequence.run_test(@test)
      end

      #confirm that the instance variables that should be counted are counted correctly
      @sequence.instance_variable_get(:@invalid_district_count);
      @sequence.instance_variable_get(:@invalid_position_count);
      @sequence.instance_variable_get(:@invalid_vtrcks_count);


    end

    it 'fails when nothing is returned' do
      instance_copy = @instance.clone
      @sequence = @sequence_class.new(instance_copy, @client)
      @sequence.instance_variable_set(:@manifest, @sample_manifest_file);
      @sequence.instance_variable_set(:@location_urls, @locations);


      body = ''


      stub_request(:get, @location)
        .to_return(status: 200, body: body, headers: {})
      pass_exception = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end
    end
  end

  #11, 12, 13, 14
  describe 'location contains VTRcks PIN tests' do
    before do
      #run the :location_valid test in preparation for the tests after
      @location_valid_test = @sequence_class[:location_valid]
      instance_copy = @instance.clone
      @sequence = @sequence_class.new(instance_copy, @client)
      @sequence.instance_variable_set(:@manifest, @sample_manifest_file);
      @sequence.instance_variable_set(:@location_urls, @locations);

      body = '{"resourceType":"Location","id":"0","name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}]}
              {"resourceType":"Location","id":"0","name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}
              {"resourceType":"Location","name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}
              {"resourceType":"Location","id":"0","name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}]}
              {"resourceType":"Location","id":"0","name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}
              {"resourceType":"Location","name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}'

      stub_request(:get, @location).to_return(status: 200, body: body, headers: {})
      @sequence.run_test(@location_valid_test)

      @test = @sequence_class[:location_optional_vtrcks_pin]

    end
    it 'succeeds when location has VTRcks PIN' do
      instance_copy = @instance.clone
      @sequence = @sequence_class.new(instance_copy, @client)

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      #check message to confirm that their is the correct number of invalid V
    end
  end



  

end

