require 'fhir_client'
require 'pry'
require './lib/sequence_base'
require './models/testing_instance'
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
      test[:sequence_required] = !klass.optional?
      test
    end
  end.flatten

  csv_out = CSV.generate do |csv|
    csv << ['Version', VERSION, 'Generated', Time.now]
    csv << ['', '', '', '', '']
    csv << ['Sequence/Group', 'Test Name', 'Required?', 'Description/Requirement', 'Reference URI']
    flat_tests.each do |test|
      csv <<  [ test[:sequence], test[:name], test[:sequence_required] && test[:required], test[:description], test[:url] ]
    end
  end

  puts csv_out

end

desc 'Execute sequence against a FHIR server'
task :execute_sequence, [:sequence, :server] do |task, args|

  REQUEST_HEADERS = { 'Accept'=>'application/json+fhir',
                      'Accept-Charset'=>'UTF-8',
                      'Content-Type'=>'application/json+fhir;charset=UTF-8'
                     }

  RESPONSE_HEADERS = {'content-type'=>'application/json+fhir;charset=UTF-8'}

  @sequence = nil
  SequenceBase.ordered_sequences.map do |seq|
    if seq.sequence_name == args[:sequence]
      @sequence = seq
    end
  end

  if @sequence == nil
    puts "Sequence not found."
    exit
  end

  binding.pry
  instance = TestingInstance.new(url: args[:server])
  instance.save!
  client = FHIR::Client.new(args[:server])
  client.use_dstu2
  client.default_json
  sequence_instance = sequence_to_run.new(instance, client, true)
  sequence_result = sequence_instance.start
  
  puts sequence_result.test_results.all
  
end

