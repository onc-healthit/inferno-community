# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/app/utils/bcp_13'

describe Inferno::BCP47 do
  before do
    @bcp47 = Inferno::Terminology::BCP13
  end

  it 'can load all MIME types' do
    result = @bcp47.code_set
    !result.empty?
  end

  it 'MIME types include application/fhir+json' do
    result = @bcp47.code_set
    result.any? { |r| r[:code] == 'application/fhir+json' }
  end
end
