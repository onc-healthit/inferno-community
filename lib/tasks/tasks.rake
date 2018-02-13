require 'fhir_client'
require 'pry'
require './lib/sequence_base'
require 'dm-core'

['lib', 'models'].each do |dir|
  Dir.glob(File.join(File.expand_path('../..', File.dirname(File.absolute_path(__FILE__))),dir, '**','*.rb')).each do |file|
    require file
  end
end

desc 'Generate List of All Tests'
task :all_tests do

  out = SequenceBase.subclasses.map do |klass|
    klass.tests.map do |test|
      test[:sequence] = klass.to_s
      test
    end
  end.flatten.sort_by { |t| t[:test_index] }

  puts = 'Sequence\tName\tDescription\tUrl"\n'
  puts out.map { |test| "#{test[:sequence]}\t#{test[:name]}\t#{test[:description]}\t#{test[:url]}" }.join("\n")

end

