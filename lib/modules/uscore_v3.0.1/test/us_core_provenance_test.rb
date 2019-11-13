# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore301ProvenanceSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore301ProvenanceSequence
    @base_url = 'http://www.example.com/fhir'
    @client = FHIR::Client.new(@base_url)
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(token: @token)
    @patient_id = '123'
    @instance.patient_id = @patient_id
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end
end
