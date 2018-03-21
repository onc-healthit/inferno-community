require 'fhir_client'
require 'pry'
require './lib/sequence_base'
require 'dm-core'
require 'csv'

['lib', 'models'].each do |dir|
  Dir.glob(File.join(File.expand_path('../..', File.dirname(File.absolute_path(__FILE__))),dir, '**','*.rb')).each do |file|
    require file
  end
end

desc 'Generate List of All Tests'
task :tests_to_csv do

  flat_tests = SequenceBase.ordered_sequences.map do |klass|
    klass.tests.map do |test|
      test[:sequence] = klass.to_s
      test
    end
  end.flatten

  csv_out = CSV.generate do |csv|
    csv << ['Version', VERSION, 'Generated', Time.now]
    csv << ['', '', '', '', '']
    csv << ['Sequence', 'Name', 'Required', 'Description', 'Url']
    flat_tests.each do |test|
      csv <<  [ test[:sequence], test[:name], test[:required], test[:description], test[:url] ]
    end
  end

  puts csv_out

end

