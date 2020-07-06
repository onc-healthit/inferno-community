# frozen_string_literal: true

require_relative '../../../../test/test_helper'
require_relative '../bcp47'

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
end
