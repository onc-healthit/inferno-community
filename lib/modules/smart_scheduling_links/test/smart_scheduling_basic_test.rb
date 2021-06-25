# frozen_string_literal: true

require_relative '../../../../test/test_helper'
require 'json'

describe Inferno::Sequence::SmartSchedulingLinksBasicSequence do
  before do
    @sequence_class = Inferno::Sequence::SmartSchedulingLinksBasicSequence
    @base_url = 'http://www.example.com/fhir'

    @manifest_url = 'http://www.example.com/$bulk-manifest'
    @location = 'http://www.example.com/locations.ndjson'
    @locations = [@location]
    @schedule = 'http://www.example.com/schedules.ndjson'
    @schedules = [@schedule]
    @slot = 'http://www.example.com/slots.ndjson'
    @slots = [@slot]

    @instance = Inferno::TestingInstance.create(url: @base_url, token: @token, selected_module: 'smart_scheduling_links')

    @client = FHIR::Client.for_testing_instance(@instance)

    @fixture = 'manifest_file'
    @sample_manifest_file = load_json_fixture(@fixture.to_sym)
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

    # it 'throws warning with custom header' do
    #   valid_json = '{"test" : "test"}'
    #   stub_request(:get, @manifest_url)
    #     .to_return(status: 200, body: valid_json, headers: {})
    #   instance_copy = @instance.clone
    #   instance_copy.manifest_url = @manifest_url
    #   instance_copy.custom_header = 'X-Request-Id:5'
    #   sequence = @sequence_class.new(instance_copy, @client)

    #   sequence.wrap_test(@manifest_downloadable_test)

    #   puts '--------------------------'
    #   puts sequence.instance_variable_get(:@test_warnings)
    #   puts '--------------------------'

    #   assert sequence.instance_variable_get(:@test_warnings).count == 1, 'There should be a warning.'
    # end
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

    ['2015-02-07T13:28:17.239+02:00',
     '2015-02-07T13:28:17.239-02:00',
     '2015-02-07T13:28:17.239Z',
     '2015-02-07T13:28Z'].each do |transaction_time|
      it 'succeeds when manifest file has transactionTime with different timezone offsets' do
        instance_copy = @instance.clone
        sequence = @sequence_class.new(instance_copy, @client)
        manifest_with_offset = @sample_manifest_file.clone
        manifest_with_offset['transactionTime'] = transaction_time
        sequence.instance_variable_set(:@manifest, manifest_with_offset)
        assert_raises(Inferno::PassException) do
          sequence.run_test(@manifest_minimum_requirement_test)
        end
      end
    end

    it 'fails when missing transactionTime' do
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)

      sample_manifest_file_missing_transaction_time = {
        "request": 'http://www.example.com/$bulk-publish',
        "output": [
          {
            "type": 'Location',
            "url": 'http://www.example.com/locations.ndjson'
          },
          {
            "type": 'Schedule',
            "url": 'http://www.example.com/schedules.ndjson'
          },
          {
            "type": 'Slot',
            "url": 'http://www.example.com/slots-2021-W09.ndjson',
            "extension": {
              "state": [
                'MA'
              ]
            }
          }
        ]
      }

      sequence.instance_variable_set(:@manifest, sample_manifest_file_missing_transaction_time)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(@manifest_minimum_requirement_test)
      end
    end

    ['2021-03-10 18:16:34.535Z', '2021-03-10T18:16:34.535', '2021-03-10T18:16:34.535+11'].each do |invalid_time|
      it 'fails when transactionTime is not a valid format' do
        instance_copy = @instance.clone
        sequence = @sequence_class.new(instance_copy, @client)

        manifest_invalid_time = @sample_manifest_file.clone
        manifest_invalid_time['transactionTime'] = invalid_time

        sequence.instance_variable_set(:@manifest, manifest_invalid_time)

        assert_raises(Inferno::AssertionException) do
          sequence.run_test(@manifest_minimum_requirement_test)
        end
      end
    end

    it 'fails when missing request' do
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)

      sample_manifest_file_missing_request = {
        "transactionTime": '2021-03-10T18:16:34.535Z',
        "output": [
          {
            "type": 'Location',
            "url": 'http://www.example.com/locations.ndjson'
          },
          {
            "type": 'Schedule',
            "url": 'http://www.example.com/schedules.ndjson'
          },
          {
            "type": 'Slot',
            "url": 'http://www.example.com/slots-2021-W09.ndjson',
            "extension": {
              "state": [
                'MA'
              ]
            }
          }
        ]
      }

      sequence.instance_variable_set(:@manifest, sample_manifest_file_missing_request)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(@manifest_minimum_requirement_test)
      end
    end

    it 'fails when missing output' do
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)

      sample_manifest_file_missing_output = {
        "transactionTime": '2021-03-10T18:16:34.535Z',
        "request": 'http://www.example.com/$bulk-publish'
      }

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
      assert_raises(Inferno::PassException) do
        sequence.run_test(@manifest_contains_jurisdictions_test)
      end
    end

    it 'fails when state is not an array' do
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)

      sample_manifest_file_state_not_array = JSON.parse('{
        "request": "http://www.example.com/$bulk-publish",
        "output": [
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
              "state": 1
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
        "request": "http://www.example.com/$bulk-publish",
        "output": [
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
              "state": ["MAA"]
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
      instance_copy.manifest_since = 'not-a-date'
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
      manifest_since_url = @manifest_url + '?_since=' + instance_copy.manifest_since
      stub_request(:get, manifest_since_url)
        .to_return(status: 200, body: manifest_since, headers: {})

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

    it 'fails when since parameter is provided but since response is the same' do
      instance_copy = @instance.clone
      instance_copy.manifest_since = '2021-04-02'
      instance_copy.manifest_url = @manifest_url
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)

      manifest_since_url = @manifest_url + '?_since=2021-04-02'
      stub_request(:get, manifest_since_url)
        .to_return(status: 200, body: @sample_manifest_file.to_s, headers: {})

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
        .to_return(status: 500, body: @sample_manifest_file.to_s, headers: {})

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

  # 6
  describe 'location resources contain valid FHIR resources' do
    before do
      @location_valid_test = @sequence_class[:location_valid]
    end

    it 'skips when there is no manifest' do
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, nil)
      assert_raises(Inferno::SkipException) do
        sequence.run_test(@location_valid_test)
      end
    end

    it 'skips when there are no location urls' do
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@location_urls, [])

      assert_raises(Inferno::SkipException) do
        sequence.run_test(@location_valid_test)
      end
    end

    it 'fail when invalid resources' do
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@location_urls, @locations)

      body = '{"resourceType":"Location","id":"0", "name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}
                {"resourceType":"Location", "id":"0", "name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}
                {"resourceType":"Location","id":"0", "name":"SMART Vaccine Clinic Boston","address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}
                {"resourceType":"Location","id":"0", "name":"SMART Vaccine Clinic Boston","telecom":[{"value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}
                {"resourceType":"Location","id":"0", "name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}
                {"resourceType":"Location","id":"0", "name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}]}
                {"resourceType":"Location","id":"0", "name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"city":"Boston","state":"MA","postalCode":"02114"}}
                {"resourceType":"Location","id":"0", "name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"state":"MA","postalCode":"02114"}}
                {"resourceType":"Location","id":"0", "name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","postalCode":"02114"}}'

      stub_request(:get, @location)
        .to_return(status: 200, body: body, headers: {})

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(@location_valid_test)
      end
    end

    it 'succeeds when location has valid FHIR resources' do
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@location_urls, @locations)

      body = '{"resourceType":"Location","id":"0", "name":"SMART Vaccine Clinic Boston","telecom":[{"system":"phone","value":"000-000-0000"}],"address":{"line":["123 Summer St"],"city":"Boston","state":"MA","postalCode":"02114"}}'

      stub_request(:get, @location)
        .to_return(status: 200, body: body, headers: {})

      assert_raises(Inferno::PassException) do
        sequence.run_test(@location_valid_test)
      end
    end
  end

  # 7
  describe 'location optional district' do
    it 'skips if no manifest' do
      location_optional_district_test = @sequence_class[:location_optional_district]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)

      sequence.instance_variable_set(:@location_urls, @locations)
      sequence.instance_variable_set(:@location_reference_ids, ['Location/0', 'Location/1', 'Location/2', 'Location/3'])

      assert_raises(Inferno::SkipException) do
        sequence.run_test(location_optional_district_test)
      end
    end

    it 'skips if location urls is empty' do
      location_optional_district_test = @sequence_class[:location_optional_district]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@location_urls, [])
      sequence.instance_variable_set(:@location_reference_ids, ['Location/0', 'Location/1', 'Location/2', 'Location/3'])

      assert_raises(Inferno::SkipException) do
        sequence.run_test(location_optional_district_test)
      end
    end

    it 'skips if location reference ids is empty' do
      location_optional_district_test = @sequence_class[:location_optional_district]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@location_urls, @locations)
      sequence.instance_variable_set(:@location_reference_ids, [])

      assert_raises(Inferno::SkipException) do
        sequence.run_test(location_optional_district_test)
      end
    end

    it 'passes if 0 invalid vtrcks ' do
      location_optional_district_test = @sequence_class[:location_optional_district]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@location_urls, @locations)
      sequence.instance_variable_set(:@location_reference_ids, ['Location/0', 'Location/1', 'Location/2', 'Location/3'])

      sequence.instance_variable_set(:@invalid_district_count, 0)

      sequence.run_test(location_optional_district_test)
    end

    it 'passes if 0 invalid vtrcks ' do
      location_optional_district_test = @sequence_class[:location_optional_district]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@location_urls, @locations)
      sequence.instance_variable_set(:@location_reference_ids, ['Location/0', 'Location/1', 'Location/2', 'Location/3'])

      sequence.instance_variable_set(:@invalid_district_count, 4)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(location_optional_district_test)
      end
    end
  end

  # 8
  describe 'location optional descriptions test' do
    it 'skips if no manifest' do
      location_optional_description_test = @sequence_class[:location_optional_description]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)

      sequence.instance_variable_set(:@location_urls, @locations)
      sequence.instance_variable_set(:@location_reference_ids, ['Location/0', 'Location/1', 'Location/2', 'Location/3'])
      sequence.instance_variable_set(:@invalid_description_count, 0)

      assert_raises(Inferno::SkipException) do
        sequence.run_test(location_optional_description_test)
      end
    end

    it 'skips if no location urls' do
      location_optional_description_test = @sequence_class[:location_optional_description]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)

      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@location_urls, [])
      sequence.instance_variable_set(:@location_reference_ids, ['Location/0', 'Location/1', 'Location/2', 'Location/3'])
      sequence.instance_variable_set(:@invalid_description_count, 0)

      assert_raises(Inferno::SkipException) do
        sequence.run_test(location_optional_description_test)
      end
    end

    it 'skips if no location reference ids' do
      location_optional_description_test = @sequence_class[:location_optional_description]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)

      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@location_urls, @locations)
      sequence.instance_variable_set(:@location_reference_ids, [])
      sequence.instance_variable_set(:@invalid_description_count, 0)

      assert_raises(Inferno::SkipException) do
        sequence.run_test(location_optional_description_test)
      end
    end

    it 'fails if invalid descriptions' do
      location_optional_description_test = @sequence_class[:location_optional_description]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)

      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@location_urls, @locations)
      sequence.instance_variable_set(:@location_reference_ids, ['Location/0', 'Location/1', 'Location/2', 'Location/3'])
      sequence.instance_variable_set(:@invalid_description_count, 3)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(location_optional_description_test)
      end
    end

    it 'passes if no invalid descriptions' do
      location_optional_description_test = @sequence_class[:location_optional_description]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)

      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@location_urls, @locations)
      sequence.instance_variable_set(:@location_reference_ids, ['Location/0', 'Location/1', 'Location/2', 'Location/3'])
      sequence.instance_variable_set(:@invalid_description_count, 0)

      sequence.run_test(location_optional_description_test)
    end
  end

  # 9
  describe 'location optional position test' do
    it 'skips if no manifest' do
      location_optional_position_test = @sequence_class[:location_optional_position]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)

      sequence.instance_variable_set(:@location_urls, @locations)
      sequence.instance_variable_set(:@location_reference_ids, ['Location/0', 'Location/1', 'Location/2', 'Location/3'])
      sequence.instance_variable_set(:@invalid_position_count, 0)

      assert_raises(Inferno::SkipException) do
        sequence.run_test(location_optional_position_test)
      end
    end

    it 'skips if no location urls' do
      location_optional_position_test = @sequence_class[:location_optional_position]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)

      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@location_urls, [])
      sequence.instance_variable_set(:@location_reference_ids, ['Location/0', 'Location/1', 'Location/2', 'Location/3'])
      sequence.instance_variable_set(:@invalid_position_count, 0)

      assert_raises(Inferno::SkipException) do
        sequence.run_test(location_optional_position_test)
      end
    end

    it 'skips if no location reference ids' do
      location_optional_position_test = @sequence_class[:location_optional_position]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)

      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@location_urls, @locations)
      sequence.instance_variable_set(:@location_reference_ids, [])
      sequence.instance_variable_set(:@invalid_position_count, 0)

      assert_raises(Inferno::SkipException) do
        sequence.run_test(location_optional_position_test)
      end
    end

    it 'fails if invalid descriptions' do
      location_optional_position_test = @sequence_class[:location_optional_position]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)

      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@location_urls, @locations)
      sequence.instance_variable_set(:@location_reference_ids, ['Location/0', 'Location/1', 'Location/2', 'Location/3'])
      sequence.instance_variable_set(:@invalid_position_count, 3)

      assert_raises(Inferno::AssertionException) do
        sequence.run_test(location_optional_position_test)
      end
    end

    it 'passes if no invalid descriptions' do
      location_optional_position_test = @sequence_class[:location_optional_position]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)

      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@location_urls, @locations)
      sequence.instance_variable_set(:@location_reference_ids, ['Location/0', 'Location/1', 'Location/2', 'Location/3'])
      sequence.instance_variable_set(:@invalid_position_count, 0)

      sequence.run_test(location_optional_position_test)
    end
  end

  # 10
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
      assert_raises(Inferno::PassException) do
        sequence.run_test(schedule_valid_test)
      end
    end

    it 'counts location references' do
      schedule_valid_test = @sequence_class[:schedule_valid]
      instance_copy = @instance.clone
      sequence = @sequence_class.new(instance_copy, @client)
      sequence.instance_variable_set(:@manifest, @sample_manifest_file)
      sequence.instance_variable_set(:@schedule_urls, @schedules)
      sequence.instance_variable_set(:@location_reference_ids, ['Location/0', 'Location/1', 'Location/2', 'Location/3'])

      body = '{"resourceType":"Schedule","id":"10","serviceType":[{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/service-type","code":"57","display":"Immunization"},{"system":"http://fhir-registry.smarthealthit.org/CodeSystem/service-type","code":"covid19-immunization","display":"COVID-19 Immunization Appointment"}]}],"actor":[{"reference":"Location/0"}]}
              {"resourceType":"Schedule","id":"11","serviceType":[{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/service-type","code":"57","display":"Immunization"},{"system":"http://fhir-registry.smarthealthit.org/CodeSystem/service-type","code":"covid19-immunization","display":"COVID-19 Immunization Appointment"}]}],"actor":[{"reference":"Location/1"}]}
              {"resourceType":"Schedule","id":"12","serviceType":[{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/service-type","code":"57","display":"Immunization"},{"system":"http://fhir-registry.smarthealthit.org/CodeSystem/service-type","code":"covid19-immunization","display":"COVID-19 Immunization Appointment"}]}],"actor":[{"reference":"Location/4"}]}
              {"resourceType":"Schedule","id":"13","serviceType":[{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/service-type","code":"57","display":"Immunization"},{"system":"http://fhir-registry.smarthealthit.org/CodeSystem/service-type","code":"covid19-immunization","display":"COVID-19 Immunization Appointment"}]}],"actor":[{"reference":"Location/5"}]}'

      stub_request(:get, @schedule).to_return(status: 200, body: body, headers: {})

      assert_raises(Inferno::PassException) do
        sequence.run_test(schedule_valid_test)
      end

      assert_equal(sequence.instance_variable_get(:@unknown_location_reference_count), 2) # Slots 21
    end
  end

  # 11
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

  # 12
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
      assert_raises(Inferno::PassException) do
        sequence.run_test(slot_valid_test)
      end
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

      assert_raises(Inferno::PassException) do
        sequence.run_test(slot_valid_test)
      end

      # check counts for invalid booking link, invalid booking phone, and invalid capacity
      assert_equal(sequence.instance_variable_get(:@unknown_schedule_reference_count), 1) # Slots 21
    end
  end

  # 13
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
end
