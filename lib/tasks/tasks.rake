require 'fhir_client'
require 'pry'
require './lib/sequence_base'
require File.expand_path '../../../app.rb', __FILE__
require './models/testing_instance'
require 'dm-core'
require 'csv'
require 'colorize'

require_relative '../app/helpers/configuration'

['lib', 'models'].each do |dir|
  Dir.glob(File.join(File.expand_path('../..', File.dirname(File.absolute_path(__FILE__))),dir, '**','*.rb')).each do |file|
    require file
  end
end

desc 'Generate List of All Tests'
task :tests_to_csv, [:group, :filename] do |task, args|
  args.with_defaults(group: 'active', filename: 'testlist.csv')
  case args.group
  when 'active'
    test_group = Inferno::Sequence::SequenceBase.ordered_sequences.reject {|sb| sb.inactive?}
  when 'inactive'
    test_group = Inferno::Sequence::SequenceBase.ordered_sequences.select {|sb| sb.inactive?}
  when 'all'
    test_group = Inferno::Sequence::SequenceBase.ordered_sequences
  else
    puts "#{args.group} is not valid argument.  Valid arguments include:
                active
                inactive
                all"
    exit
  end

  flat_tests = test_group.map  do |klass|
    klass.tests.map do |test|
      test[:sequence] = klass.to_s
      test[:sequence_required] = !klass.optional?
      test
    end
  end.flatten

  csv_out = CSV.generate do |csv|
    csv << ['Version', VERSION, 'Generated', Time.now]
    csv << ['', '', '', '', '']
    csv << ['Test ID', 'Reference', 'Sequence/Group', 'Test Name', 'Required?', 'Description/Requirement', 'Reference URI']
    flat_tests.each do |test|
      csv <<  [test[:test_id], test[:ref], test[:sequence], test[:name], test[:sequence_required] && test[:required], test[:description], test[:url] ]
    end
  end

  File.write(args.filename, csv_out)

end

desc 'Execute sequence against a FHIR server'
task :execute_sequence, [:sequence, :server] do |task, args|

  @sequence = nil
  Inferno::Sequence::SequenceBase.ordered_sequences.map do |seq|
    if seq.sequence_name == args[:sequence] + "Sequence"
      @sequence = seq
    end
  end

  if @sequence == nil
    puts "Sequence not found. Valid sequences are:
            Conformance,
            DynamicRegistration,
            PatientStandaloneLaunch,
            ProviderEHRLaunch,
            OpenIDConnect,
            TokenIntrospection,
            TokenRefresh,
            ArgonautDataQuery,
            ArgonautProfiles,
            AdditionalResources"
    exit
  end

  instance = Inferno::Models::TestingInstance.new(url: args[:server])
  instance.save!
  client = FHIR::Client.new(args[:server])
  client.use_dstu2
  client.default_json
  sequence_instance = @sequence.new(instance, client, true)
  sequence_result = sequence_instance.start
  
  checkmark = "\u2713"
  puts @sequence.sequence_name + " Sequence: "  
  sequence_result.test_results.each do |result|
    print "\tTest: #{result.name} - "
    if result.result == 'pass'
      puts 'pass '.green + checkmark.encode('utf-8').green
    elsif result.result == 'skip'
      puts 'skip '.yellow + '*'.yellow
    elsif result.result == 'fail'
      if result.required == 'true'
        puts 'fail '.red + 'X'.red
      else
        puts 'fail X (optional)'.light_black
      end
    end
  end
  print @sequence.sequence_name + " Sequence Result: " 
  if sequence_result.result == 'pass'
    puts 'pass '.green + checkmark.encode('utf-8').green
  elsif sequence_result.result == 'fail'
    puts 'fail '.red + 'X'.red
    exit 1
  end
    
  
end

