module Inferno
  class Model

    class << self

      def configure_model
        DataMapper::Logger.new($stdout, :debug) if settings.environment == :development
        DataMapper::Model.raise_on_save_failure = true


        DataMapper.setup(:default, "sqlite3:data/#{settings.environment.to_s}_data.db")

        require './lib/sequence_base'
        ['lib', 'models'].each do |dir|
          Dir.glob(File.join(File.dirname(File.absolute_path(__FILE__)),dir, '**','*.rb')).each do |file|
            require file
          end
        end

        DataMapper.finalize
      end

      def create_tables
        [TestingInstance, SequenceResult, TestResult, TestWarning, RequestResponse, RequestResponseTestResult, SupportedResource, ResourceReference].each do |model|
          if settings.purge_database_on_reload || settings.environment == :test
            model.auto_migrate!
          else
            model.auto_upgrade!
          end
        end
      end
    end
  end
end
