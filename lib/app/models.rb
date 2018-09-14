#DataMapper::Logger.new($stdout, :debug) if settings.environment == :development
DataMapper::Model.raise_on_save_failure = true

# DataMapper::Logger.new($stdout, :debug) if Inferno::ENVIRONMENT == :development
DataMapper.setup(:default, "sqlite3:data/#{Inferno::ENVIRONMENT.to_s}_data.db")

require_relative 'models/request_response'
require_relative 'models/resource_reference'
require_relative 'models/sequence_result'
require_relative 'models/supported_resource'
require_relative 'models/test_result'
require_relative 'models/test_warning'
require_relative 'models/testing_instance'

DataMapper.finalize

#[Inferno::Models::TestingInstance,
# Inferno::Models::SequenceResult,
# Inferno::Models::TestResult,
# Inferno::Models::TestWarning,
# Inferno::Models::RequestResponse,
# Inferno::Models::RequestResponse,
# Inferno::Models::TestResult,
# Inferno::Models::SupportedResource,
# Inferno::Models::ResourceReference].each(&:auto_upgrade!)
# Inferno::Models::ResourceReference].each(&:auto_upgrade!)


if Inferno::PURGE_ON_RELOAD || Inferno::ENVIRONMENT == :test
  DataMapper.auto_migrate!
else
  DataMapper.auto_upgrade!
end
#DataMapper.auto_upgrade!
