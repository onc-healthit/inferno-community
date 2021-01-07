# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/app/utils/bcp47'

languages = "File-Date: 2020-12-16
%%
Type: language
Subtag: fo
Description: Foo
Added: 2020-12-16
%%
Type: language
Subtag: bar
Description: Bar
Added: 2020-12-16
%%
Type: extlang
Subtag: extlang1
Description: Extlang 1
Added: 2020-12-16
%%
Type: extension
Subtag: -extension1-
Description: Extension 1
Added: 2020-12-16
%%"

describe Inferno::BCP47 do
  before do
    stub_request(:get, 'https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry')
      .to_return(status: 200, body: languages, headers: {})
    @bcp47 = Inferno::BCP47
  end

  it 'can load all languages' do
    @bcp47.filter_codes.length == 2
  end

  it 'return all extlang' do
    filter = FHIR::ValueSet::Compose::Include::Filter.new(
      'op' => 'exists',
      'property' => 'ext-lang',
      'value' => 'true'
    )
    result = @bcp47.filter_codes(filter)
    result.length == 1
  end

  it 'return all extension' do
    filter = FHIR::ValueSet::Compose::Include::Filter.new(
      'op' => 'exists',
      'property' => 'extension',
      'value' => 'true'
    )
    result = @bcp47.filter_codes(filter)
    result.length == 1
  end
end
