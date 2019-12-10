# frozen_string_literal: true

DataMapper::Model.raise_on_save_failure = true

DataMapper.setup(:default, "sqlite3:data/#{Inferno::ENVIRONMENT}_data.db")

require_relative 'models/request_response'
require_relative 'models/resource_reference'
require_relative 'models/sequence_result'
require_relative 'models/test_result'
require_relative 'models/test_warning'
require_relative 'models/testing_instance'

DataMapper.finalize

if Inferno::PURGE_ON_RELOAD || Inferno::ENVIRONMENT == :test
  DataMapper.auto_migrate!
else
  DataMapper.auto_upgrade!
end
