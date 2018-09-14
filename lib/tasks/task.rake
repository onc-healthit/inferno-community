require 'fhir_client'
require 'pry'
#require File.expand_path '../../../app.rb', __FILE__
#require './models/testing_instance'
require 'dm-core'
require 'csv'
require 'colorize'
require 'optparse'

require_relative '../app'
require_relative '../app/endpoint'
require_relative '../app/helpers/configuration'
require_relative '../app/sequence_base'
require_relative '../app/models'

include Inferno

def suppress_output
  begin
    original_stderr = $stderr.clone
    original_stdout = $stdout.clone
    $stderr.reopen(File.new('/dev/null', 'w'))
    $stdout.reopen(File.new('/dev/null', 'w'))
    retval = yield
  rescue Exception => e
    $stdout.reopen(original_stdout)
    $stderr.reopen(original_stderr)
    raise e
  ensure
    $stdout.reopen(original_stdout)
    $stderr.reopen(original_stderr)
  end
  retval
end

def print_requests(result)
  result.request_responses.map do |req_res|
    req_res.response_code.to_s + ' ' + req_res.request_method.upcase + ' ' + req_res.request_url
  end
end

def execute(instance, sequences)

  client = FHIR::Client.new(instance.url)
  client.use_dstu2
  client.default_json

  sequence_results = []

  fails = false

  system "clear"
  puts "\n"
  puts "==========================================\n"
  puts " Testing #{sequences.length} Sequences"
  puts "==========================================\n"
  sequences.each do |sequence_info|

    sequence = sequence_info['sequence']
    sequence_info.each do |key, val|
      if key != 'sequence'
        instance.send("#{key.to_s}=", val) if instance.respond_to? key.to_s
      end
    end
    sequence_instance = sequence.new(instance, client, true)
    sequence_result = nil

    suppress_output{sequence_result = sequence_instance.start}

    sequence_results << sequence_result

    checkmark = "\u2713"
    puts "\n" + sequence.sequence_name + " Sequence: \n"
    sequence_result.test_results.each do |result|
      print " "
      if result.result == 'pass'
        print "#{checkmark.encode('utf-8')} pass".green
        print " - #{result.name}\n"
      elsif result.result == 'skip'
        print "* skip".yellow
        print " - #{result.name}\n"
        puts "    Message: #{result.message}"
      elsif result.result == 'fail'
        if result.required
          print "X fail".red
          print " - #{result.name}\n"
          puts "    Message: #{result.message}"
          print_requests(result).map do |req|
            puts "    #{req}"
          end
          fails = true
        else
          print "X fail (optional)".light_black
          print " - #{result.name}\n"
          puts "    Message: #{result.message}"
          print_requests(result).map do |req|
            puts "      #{req}"
          end
        end
      elsif sequence_result.result == 'error'
        print "X error".magenta
        print " - #{result.name}\n"
        print "    Message: #{result.message}"
        print_requests(result).map do |req|
          puts "      #{req}"
        end
        fails = true
      end
    end
    print "\n" + sequence.sequence_name + " Sequence Result: "
    if sequence_result.result == 'pass'
      puts 'pass '.green + checkmark.encode('utf-8').green
    elsif sequence_result.result == 'fail'
      puts 'fail '.red + 'X'.red
      fails = true
    elsif sequence_result.result == 'error'
      puts 'error '.magenta + 'X'.magenta
      fails = true
    elsif sequence_result.result == 'skip'
      puts 'skip '.yellow + '*'.yellow
    # else
    #   binding.pry
    end
    puts "---------------------------------------------\n"
  end

  failures_count = "" + sequence_results.select{|s| s.result == 'fail'}.count.to_s
  passed_count = "" + sequence_results.select{|s| s.result == 'pass'}.count.to_s
  skip_count = "" + sequence_results.select{|s| s.result == 'skip'}.count.to_s
  print " Result: " + failures_count.red + " failed, " + passed_count.green + " passed"
  if sequence_results.select{|s| s.result == 'skip'}.count > 0
    print (", " + sequence_results.select{|s| s.result == 'skip'}.count.to_s).yellow + " skipped"
  end
  if sequence_results.select{|s| s.result == 'error'}.count > 0
    print (", " + sequence_results.select{|s| s.result == 'error'}.count.to_s).yellow + " error"
  end
  puts "\n=============================================\n"

  return_value = 0
  return_value = 1 if fails

  return_value

end

namespace :inferno do |argv|

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

  desc 'Generate automated run configuration'
  task :generate_config, [:server] do |task, args|

    sequences = []
    requires = []
    defines = []

    input = ''

    output = {server: args[:server], arguments: {}, sequences: []}
    Inferno::Sequence::SequenceBase.ordered_sequences.each do |seq|
      unless input == 'a'
        print "\nInclude #{seq.name} (y/n/a)? "
        input = STDIN.getc
      end

      if input == 'a' || input == 'y'
        output[:sequences].push({sequence: seq.name.demodulize})
        sequences << seq
        seq.requires.each do |req|
          requires << req unless (requires.include?(req) || defines.include?(req) || req == :url)
        end
        defines.push(*seq.defines)
      end

    end

    STDOUT.print "\n"

    requires.each do |req|
      input = ""

      if req == :initiate_login_uri
        input = 'http://localhost:4568/launch'
      elsif req == :redirect_uris
        input = 'http://localhost:4568/redirect'
      else
        STDOUT.flush
        STDOUT.print "\nEnter #{req.to_s.upcase}: "
        STDOUT.flush
        input = STDIN.gets.chomp
      end

      output[:arguments][req] = input
    end

    File.open('config.json', 'w') { |file| file.write(JSON.pretty_generate(output)) }

  end

  desc 'Execute sequence against a FHIR server'
  task :execute, [:server] do |task, args|

    FHIR.logger.level = Logger::UNKNOWN
    sequences = []
    requires = []
    defines = []

    Inferno::Sequence::SequenceBase.ordered_sequences.each do |seq|
      if args.extras.include? seq.sequence_name.split('Sequence')[0]
        seq.requires.each do |req|
          oauth_required ||= (req == :initiate_login_uri)
          requires << req unless (requires.include?(req) || defines.include?(req) || req == :url)
        end
        defines.push(*seq.defines)
        sequences << seq
      end
    end

    instance = Inferno::Models::TestingInstance.new(url: args[:server])
    instance.save!

    o = OptionParser.new

    o.banner = "Usage: rake inferno:execute [options]"
    requires.each do |req|
      o.on("--#{req.to_s} #{req.to_s.upcase}") do  |value|
        instance.send("#{req.to_s}=", value) if instance.respond_to? req.to_s
      end
    end

    args = o.order!(ARGV) {}

    o.parse!(args)

    if requires.include? :client_id
      puts 'Please register the application with the following information (enter to continue)'
      #FIXME
      puts "Launch URI: http://localhost:4567/#{base_path}/#{instance.id}/#{instance.client_endpoint_key}/launch"
      puts "Redirect URI: http://localhost:4567/#{base_path}/#{instance.id}/#{instance.client_endpoint_key}/redirect"
      STDIN.getc
      print "            \r"
    end

    input_required = false
    requires.each do |req|
      if instance.respond_to?(req) && instance.send(req).nil?
        puts "\n\nENTER REQUIRED FIELDS\n".blue unless input_required
        print "Enter #{req.to_s.upcase}: "
        instance.send("#{req}=", gets.chomp)
        input_required = true
      end
    end
    instance.save!

    if input_required
      puts ""
      puts "\nIn the future, run with the following command".blue
      puts "TODO bundle exec rake[asdfasdf,asdfsadf] -- --PARAM_1 value --PARAM_2 value"
      puts ""
      print "(enter to continue)"
      STDIN.getc
      print "            \r"
    end

    exit execute(instance, sequences.map{|s| {'sequence' => s}})

  end

  desc 'Execute sequence against a FHIR server'
  task :execute_batch, [:config] do |task, args|
    file = File.read(args.config)
    config = JSON.parse(file)

    instance = Inferno::Models::TestingInstance.new(url: config['server'])
    instance.save!
    client = FHIR::Client.new(config['server'])
    client.use_dstu2
    client.default_json

    config['arguments'].each do |req, value|
      if instance.respond_to?(req)
        instance.send("#{req}=", value)
      end
    end

    sequences = config['sequences'].map do |sequence|
      sequence_name = sequence
      out = {}
      if !sequence.is_a?(Hash)
        out = {
          'sequence' => Inferno::Sequence::SequenceBase.subclasses.find{|x| x.name.demodulize.start_with?(sequence_name)}
        }
      else
        out = sequence
        out['sequence'] = Inferno::Sequence::SequenceBase.subclasses.find{|x| x.name.demodulize.start_with?(sequence['sequence'])}
      end

      out

    end

    exit execute(instance, sequences)
  end
end
