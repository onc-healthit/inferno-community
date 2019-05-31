# frozen_string_literal: true

require 'fhir_client'
require 'pry'
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

  client.use_dstu2 if instance.module.fhir_version == 'dstu2'

  client.default_json

  sequence_results = []

  fails = false

  system 'clear'
  puts "\n"
  puts "==========================================\n"
  puts " Testing #{sequences.length} Sequences"
  puts "==========================================\n"
  sequences.each do |sequence_info|
    sequence = sequence_info['sequence']
    sequence_info.each do |key, val|
      if key != 'sequence'
        if val.is_a?(Array) || val.is_a?(Hash)
          instance.send("#{key}=", val.to_json) if instance.respond_to? key.to_s
        elsif val.is_a?(String) && val.casecmp('true').zero?
          instance.send("#{key}=", true) if instance.respond_to? key.to_s
        elsif val.is_a?(String) && val.casecmp('false').zero?
          instance.send("#{key}=", false) if instance.respond_to? key.to_s
        else
          instance.send("#{key}=", val) if instance.respond_to? key.to_s
        end
      end
    end
    instance.save
    sequence_instance = sequence.new(instance, client, false)
    sequence_result = nil

    suppress_output { sequence_result = sequence_instance.start }

    sequence_results << sequence_result

    checkmark = "\u2713"
    puts "\n" + sequence.sequence_name + " Sequence: \n"
    sequence_result.test_results.each do |result|
      print ' '
      if result.result == 'pass'
        print "#{checkmark.encode('utf-8')} pass".green
        print " - #{result.test_id} #{result.name}\n"
      elsif result.result == 'skip'
        print '* skip'.yellow
        print " - #{result.test_id} #{result.name}\n"
        puts "    Message: #{result.message}"
      elsif result.result == 'fail'
        if result.required
          print 'X fail'.red
          print " - #{result.test_id} #{result.name}\n"
          puts "    Message: #{result.message}"
          print_requests(result).map do |req|
            puts "    #{req}"
          end
          fails = true
        else
          print 'X fail (optional)'.light_black
          print " - #{result.test_id} #{result.name}\n"
          puts "    Message: #{result.message}"
          print_requests(result).map do |req|
            puts "    #{req}"
          end
        end
      elsif sequence_result.result == 'error'
        print 'X error'.magenta
        print " - #{result.test_id} #{result.name}\n"
        puts "    Message: #{result.message}"
        print_requests(result).map do |req|
          puts "      #{req}"
        end
        fails = true
      end
    end
    print "\n" + sequence.sequence_name + ' Sequence Result: '
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
    end
    puts "---------------------------------------------\n"
  end

  failures_count = '' + sequence_results.select { |s| s.result == 'fail' }.count.to_s
  passed_count = '' + sequence_results.select { |s| s.result == 'pass' }.count.to_s
  skip_count = '' + sequence_results.select { |s| s.result == 'skip' }.count.to_s
  print ' Result: ' + failures_count.red + ' failed, ' + passed_count.green + ' passed'
  if sequence_results.select { |s| s.result == 'skip' }.count > 0
    print (', ' + sequence_results.select { |s| s.result == 'skip' }.count.to_s).yellow + ' skipped'
  end
  if sequence_results.select { |s| s.result == 'error' }.count > 0
    print (', ' + sequence_results.select { |s| s.result == 'error' }.count.to_s).yellow + ' error'
  end
  puts "\n=============================================\n"

  return_value = 0
  return_value = 1 if fails

  return_value
end

namespace :inferno do |_argv|
  # Exports a CSV containing the test metadata
  desc 'Generate List of All Tests'
  task :tests_to_csv, [:module, :group, :filename] do |_task, args|
    args.with_defaults(module: 'argonaut', group: 'active')
    args.with_defaults(filename: "#{args.module}_testlist.csv")
    sequences = Inferno::Module.get(args.module)&.sequences
    if sequences.nil?
      puts "No sequence found for module: #{args.module}"
      exit
    end

    flat_tests = sequences.map do |klass|
      klass.tests.map do |test|
        test[:sequence] = klass.to_s
        test[:sequence_required] = !klass.optional?
        test
      end
    end.flatten

    csv_out = CSV.generate do |csv|
      csv << ['Version', VERSION, 'Generated', Time.now]
      csv << ['', '', '', '', '']
      csv << ['Test ID', 'Reference', 'Sequence/Group', 'Test Name', 'Required?', 'Reference URI']
      flat_tests.each do |test|
        csv << [test[:test_id], test[:ref], test[:sequence].split('::').last, test[:name], test[:sequence_required] && test[:required], test[:url]]
      end
    end

    File.write(args.filename, csv_out)
    puts "Writing to #{args.filename}"
  end

  desc 'Generate automated run script'
  task :generate_script, [:server, :module] do |_task, args|
    sequences = []
    requires = []
    defines = []

    input = ''

    output = { server: args[:server], module: args[:module], arguments: {}, sequences: [] }

    instance = Inferno::Models::TestingInstance.new(url: args[:server], selected_module: args[:module])
    instance.save!

    instance.module.sequences.each do |seq|
      unless input == 'a'
        print "\nInclude #{seq.sequence_name} (y/n/a)? "
        input = STDIN.gets.chomp
      end

      next unless input == 'a' || input == 'y'

      output[:sequences].push(sequence: seq.sequence_name)
      sequences << seq
      seq.requires.each do |req|
        requires << req unless requires.include?(req) || defines.include?(req) || req == :url
      end
      defines.push(*seq.defines)
    end

    STDOUT.print "\n"

    requires.each do |req|
      input = ''

      if req == :initiate_login_uri
        input = 'http://localhost:4568/launch'
      elsif req == :redirect_uris
        input = 'http://localhost:4568/redirect'
      else
        STDOUT.flush
        STDOUT.print "\nEnter #{req.to_s.upcase}: ".light_black
        STDOUT.flush
        input = STDIN.gets.chomp
      end

      output[:arguments][req] = input
    end

    File.open('script.json', 'w') { |file| file.write(JSON.pretty_generate(output)) }
  end

  desc 'Execute sequences against a FHIR server'
  task :execute, [:server, :module] do |_task, args|
    FHIR.logger.level = Logger::UNKNOWN
    sequences = []
    requires = []
    defines = []

    instance = Inferno::Models::TestingInstance.new(url: args[:server], selected_module: args[:module])
    instance.save!

    instance.module.sequences.each do |seq|
      next unless args.extras.empty? || args.extras.include?(seq.sequence_name.split('Sequence')[0])

      seq.requires.each do |req|
        oauth_required ||= (req == :initiate_login_uri)
        requires << req unless requires.include?(req) || defines.include?(req) || req == :url
      end
      defines.push(*seq.defines)
      sequences << seq
    end

    o = OptionParser.new

    o.banner = 'Usage: rake inferno:execute [options]'
    requires.each do |req|
      o.on("--#{req} #{req.to_s.upcase}") do |value|
        instance.send("#{req}=", value) if instance.respond_to? req.to_s
      end
    end

    arguments = o.order!(ARGV) {}

    o.parse!(arguments)

    if requires.include? :client_id
      puts 'Please register the application with the following information (enter to continue)'
      # FIXME
      puts "Launch URI: http://localhost:4567/#{base_path}/#{instance.id}/#{instance.client_endpoint_key}/launch"
      puts "Redirect URI: http://localhost:4567/#{base_path}/#{instance.id}/#{instance.client_endpoint_key}/redirect"
      STDIN.getc
      print "            \r"
    end

    input_required = false
    param_list = ''
    requires.each do |req|
      next unless instance.respond_to?(req) && instance.send(req).nil?

      puts "\nPlease provide the following required fields:\n" unless input_required
      print "  #{req.to_s.upcase}: ".light_black
      value_input = gets.chomp
      instance.send("#{req}=", value_input)
      input_required = true
      param_list = "#{param_list} --#{req.to_s.upcase} #{value_input}"
    end
    instance.save!

    if input_required
      args_list = "#{instance.url},#{args.module}"
      args_list += ",#{args.extras.join(',')}" unless args.extras.empty?

      puts ''
      puts "\nIn the future, run with the following command:\n\n"
      puts "  rake inferno:execute[#{args_list}] -- #{param_list}".light_black
      puts ''
      print '(enter to continue)'.red
      STDIN.getc
      print "            \r"
    end

    exit execute(instance, sequences.map { |s| { 'sequence' => s } })
  end

  desc 'Cleans the database of all models'
  task :drop_database, [] do |_task|
    DataMapper.auto_migrate!
  end

  desc 'Execute sequence against a FHIR server'
  task :execute_batch, [:config] do |_task, args|
    file = File.read(args.config)
    config = JSON.parse(file)

    instance = Inferno::Models::TestingInstance.new(url: config['server'], selected_module: config['module'], initiate_login_uri: 'http://localhost:4568/launch', redirect_uris: 'http://localhost:4568/redirect')
    instance.save!
    client = FHIR::Client.new(config['server'])
    client.use_dstu2 if instance.module.fhir_version == 'dstu2'
    client.default_json

    config['arguments'].each do |key, val|
      if instance.respond_to?(key)
        if val.is_a?(Array) || val.is_a?(Hash)
          instance.send("#{key}=", val.to_json) if instance.respond_to? key.to_s
        elsif val.is_a?(String) && val.casecmp('true').zero?
          instance.send("#{key}=", true) if instance.respond_to? key.to_s
        elsif val.is_a?(String) && val.casecmp('false').zero?
          instance.send("#{key}=", false) if instance.respond_to? key.to_s
        else
          instance.send("#{key}=", val) if instance.respond_to? key.to_s
        end
      end
    end

    sequences = config['sequences'].map do |sequence|
      sequence_name = sequence
      out = {}
      if !sequence.is_a?(Hash)
        out = {
          'sequence' => Inferno::Sequence::SequenceBase.descendants.find { |x| x.sequence_name.start_with?(sequence_name) }
        }
      else
        out = sequence
        out['sequence'] = Inferno::Sequence::SequenceBase.descendants.find { |x| x.sequence_name.start_with?(sequence['sequence']) }
      end

      out
    end

    exit execute(instance, sequences)
  end
end

namespace :terminology do |_argv|
  desc 'post-process LOINC Top 2000 common lab results CSV'
  task :process_loinc, [] do |_t, _args|
    require 'find'
    require 'csv'
    puts 'Looking for `./resources/terminology/Top2000*.csv`...'
    loinc_file = Find.find('resources/terminology').find { |f| /Top2000.*\.csv$/ =~f }
    if loinc_file
      output_filename = 'resources/terminology/terminology_loinc_2000.txt'
      puts "Writing to #{output_filename}..."
      output = File.open(output_filename, 'w:UTF-8')
      line = 0
      begin
        CSV.foreach(loinc_file, encoding: 'iso-8859-1:utf-8', headers: true) do |row|
          line += 1
          next if row.length <= 1 || row[1].nil? # skip the categories

          #              CODE    | DESC
          output.write("#{row[0]}|#{row[1]}\n")
        end
      rescue Exception => e
        puts "Error at line #{line}"
        puts e.message
      end
      output.close
      puts 'Done.'
    else
      puts 'LOINC file not found.'
      puts 'Download the LOINC Top 2000 Common Lab Results file'
      puts '  -> https://loinc.org/download/loinc-top-2000-lab-observations-us-csv/'
      puts 'copy it into your `./resources/terminology` folder, and rerun this task.'
    end
  end

  desc 'post-process SNOMED Core Subset file'
  task :process_snomed, [] do |_t, _args|
    require 'find'
    puts 'Looking for `./resources/terminology/SNOMEDCT_CORE_SUBSET*.txt`...'
    snomed_file = Find.find('resources/terminology').find { |f| /SNOMEDCT_CORE_SUBSET.*\.txt$/ =~f }
    if snomed_file
      output_filename = 'resources/terminology/terminology_snomed_core.txt'
      output = File.open(output_filename, 'w:UTF-8')
      line = 0
      begin
        entire_file = File.read(snomed_file)
        puts "Writing to #{output_filename}..."
        entire_file.split("\n").each do |l|
          row = l.split('|')
          line += 1
          next if line == 1 # skip the headers

          #              CODE    | DESC
          output.write("#{row[0]}|#{row[1]}\n")
        end
      rescue Exception => e
        puts "Error at line #{line}"
        puts e.message
      end
      output.close
      puts 'Done.'
    else
      puts 'SNOMEDCT file not found.'
      puts 'Download the SNOMEDCT Core Subset file'
      puts '  -> https://www.nlm.nih.gov/research/umls/Snomed/core_subset.html'
      puts 'copy it into your `./resources/terminology` folder, and rerun this task.'
    end
  end

  desc 'post-process common UCUM codes'
  task :process_ucum, [] do |_t, _args|
    require 'find'
    puts 'Looking for `./resources/terminology/concepts.tsv`...'
    ucum_file = Find.find('resources/terminology').find { |f| /concepts.tsv$/ =~f }
    if ucum_file
      output_filename = 'resources/terminology/terminology_ucum.txt'
      output = File.open(output_filename, 'w:UTF-8')
      line = 0
      begin
        entire_file = File.read(ucum_file)
        puts "Writing to #{output_filename}..."
        entire_file.split("\n").each do |l|
          row = l.split("\t")
          line += 1
          next if line == 1 # skip the headers

          output.write("#{row[0]}\n") # code
          output.write("#{row[5]}\n") if row[0] != row[5] # synonym
        end
      rescue Exception => e
        puts "Error at line #{line}"
        puts e.message
      end
      output.close
      puts 'Done.'
    else
      puts 'UCUM concepts file not found.'
      puts 'Download the UCUM concepts file'
      puts '  -> http://download.hl7.de/documents/ucum/concepts.tsv'
      puts 'copy it into your `./resources/terminology` folder, and rerun this task.'
    end
  end

  desc 'download and execute UMLS terminology data'
  task :download_umls, [:username, :password] do |_t, args|
    # Adapted from python https://github.com/jmandel/umls-bloomer/blob/master/01-download.py
    default_target_file = 'https://download.nlm.nih.gov/umls/kss/2018AB/umls-2018AB-full.zip'

    puts 'Getting Login Page'
    response = RestClient.get default_target_file
    # Get the final redirection URL
    login_page = response.history.last.headers[:location]
    action_base = login_page.split('/cas/')[0]
    action_path = response.body.split('form id="fm1" action="')[1].split('"')[0]
    execution = response.body.split('name="execution" value="')[1].split('"')[0]

    begin
      puts 'Getting Download Link'
      response = RestClient::Request.execute(method: :post,
                                             url: action_base + action_path,
                                             payload: {
                                               username: args.username,
                                               password: args.password,
                                               execution: execution,
                                               _eventId: 'submit'
                                             },
                                             max_redirects: 0)
    rescue RestClient::ExceptionWithResponse => err
      follow_redirect(err.response.headers[:location], err.response.headers[:set_cookie])
    end
    puts 'Finished Downloading!'
  end

  def follow_redirect(location, cookie = nil)
    if location
      size = 0
      percent = 0
      current_percent = 0
      File.open('umls.zip', 'w') do |f|
        block = proc do |response|
          puts response.header['content-type']
          if response.header['content-type'] == 'application/zip'
            total = response.header['content-length'].to_i
            response.read_body do |chunk|
              f.write chunk
              size += chunk.size
              percent = ((size * 100) / total).round unless total.zero?
              if current_percent != percent
                current_percent = percent
                puts "#{percent}% complete"
              end
            end
          else
            follow_redirect(response.header['location'], response.header['set-cookie'])
          end
        end
        RestClient::Request.execute(
          method: :get,
          url: location,
          headers: { cookie: cookie },
          block_response: block
        )
      end
    end
  end

  desc 'unzip umls zip'
  task :unzip_umls, [:umls_zip] do |_t, args|
    args.with_defaults(umls_zip: 'umls.zip')
    destination = 'resources/terminology/umls'
    # https://stackoverflow.com/questions/19754883/how-to-unzip-a-zip-file-containing-folders-and-files-in-rails-while-keeping-the
    Zip::File.open(args.umls_zip) do |zip_file|
      # Handle entries one by one
      zip_file.each do |entry|
        # Extract to file/directory/symlink
        puts "Extracting #{entry.name}"
        f_path = File.join(destination, entry.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(entry, f_path) unless File.exist?(f_path)
      end
    end
    Zip::File.open(File.expand_path("#{Dir["#{destination}/20*"][0]}/mmsys.zip")) do |zip_file|
      # Handle entries one by one
      zip_file.each do |entry|
        # Extract to file/directory/symlink
        puts "Extracting #{entry.name}"
        f_path = File.join((Dir["#{destination}/20*"][0]).to_s, entry.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(entry, f_path) unless File.exist?(f_path)
      end
    end
  end

  desc 'run umls jar'
  task :run_umls, [:my_config] do |_t, args|
    # More information on batch running UMLS
    # https://www.nlm.nih.gov/research/umls/implementation_resources/community/mmsys/BatchMetaMorphoSys.html
    args.with_defaults(my_config: 'all-active-exportconfig.prop')
    jre_version = if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
                    'windows64'
                  elsif (/darwin/ =~ RUBY_PLATFORM) != nil
                    'macos'
                  else linux?
                       'linux'
                  end
    puts "#{jre_version} system detected"
    config_file = Dir.pwd + "/resources/terminology/#{args.my_config}"
    output_dir = Dir.pwd + '/resources/terminology/umls_subset'
    FileUtils.mkdir(output_dir)
    puts "Using #{config_file}"
    Dir.chdir(Dir['resources/terminology/umls/20*'][0]) do
      Dir['lib/*.jar'].each do |jar|
        File.chmod(0o555, jar)
      end
      puts 'Running MetamorphoSys (this may take a while)...'
      output = system("./jre/#{jre_version}/bin/java " \
                          '-Djava.awt.headless=true ' \
                          '-cp .:lib/jpf-boot.jar ' \
                          '-Djpf.boot.config=./etc/subset.boot.properties ' \
                          '-Dlog4j.configuration=./etc/log4j.properties ' \
                          '-Dinput.uri=. ' \
                          "-Doutput.uri=#{output_dir} " \
                          "-Dmmsys.config.uri=#{config_file} " \
                          '-Xms300M -Xmx8G ' \
                          'org.java.plugin.boot.Boot')
      p output
    end
    puts 'done'
  end

  desc 'cleanup umls'
  task :cleanup_umls, [] do |_t, _args|
    puts 'removing umls.zip...'
    File.delete('umls.zip') if File.exist?('umls.zip')
    puts 'removing unzipped umls...'
    FileUtils.remove_dir('resources/terminology/umls') if File.directory?('resources/terminology/umls')
    puts 'removing umls subset...'
    FileUtils.remove_dir('resources/terminology/umls_subset') if File.directory?('resources/terminology/umls_subset')
    puts 'removing umls.db'
    File.delete('umls.db') if File.exist?('umls.db')
    puts 'removing MRCONSO.pipe'
    File.delete('MRCONSO.pipe') if File.exist?('MRCONSO.pipe')
    puts 'removing MRREL.pipe'
    File.delete('MRREL.pipe') if File.exist?('MRREL.pipe')
  end

  desc 'post-process UMLS terminology file'
  task :process_umls, [] do |_t, _args|
    require 'find'
    require 'csv'
    puts 'Looking for `./resources/terminology/MRCONSO.RRF`...'
    input_file = Find.find('resources/terminology').find { |f| /MRCONSO.RRF$/ =~f }
    if input_file
      start = Time.now
      output_filename = 'resources/terminology/terminology_umls.txt'
      output = File.open(output_filename, 'w:UTF-8')
      line = 0
      excluded = 0
      excluded_systems = Hash.new(0)
      begin
        puts "Writing to #{output_filename}..."
        CSV.foreach(input_file, headers: false, col_sep: '|', quote_char: "\x00") do |row|
          line += 1
          include_code = false
          codeSystem = row[11]
          code = row[13]
          description = row[14]
          case codeSystem
          when 'SNOMEDCT_US'
            codeSystem = 'SNOMED'
            include_code = (row[4] == 'PF' && ['FN', 'OAF'].include?(row[12]))
          when 'LNC'
            codeSystem = 'LOINC'
            include_code = true
          when 'ICD10CM'
            codeSystem = 'ICD10'
            include_code = (row[12] == 'PT')
          when 'ICD10PCS'
            codeSystem = 'ICD10'
            include_code = (row[12] == 'PT')
          when 'ICD9CM'
            codeSystem = 'ICD9'
            include_code = (row[12] == 'PT')
          when 'CPT'
            include_code = (row[12] == 'PT')
          when 'HCPCS'
            include_code = (row[12] == 'PT')
          when 'MTHICD9'
            codeSystem = 'ICD9'
            include_code = true
          when 'RXNORM'
            include_code = true
          when 'CVX'
            include_code = ['PT', 'OP'].include?(row[12])
          when 'SRC'
            # 'SRC' rows define the data sources in the file
            include_code = false
          else
            include_code = false
            excluded_systems[codeSystem] += 1
          end
          if include_code
            output.write("#{codeSystem}|#{code}|#{description}\n")
          else
            excluded += 1
          end
        end
      rescue Exception => e
        puts "Error at line #{line}"
        puts e.message
      end
      output.close
      puts "Processed #{line} lines, excluding #{excluded} redundant entries."
      puts "Excluded code systems: #{excluded_systems}" unless excluded_systems.empty?
      finish = Time.now
      minutes = ((finish - start) / 60)
      seconds = (minutes - minutes.floor) * 60
      puts "Completed in #{minutes.floor} minute(s) #{seconds.floor} second(s)."
      puts 'Done.'
    else
      download_umls_notice
    end
  end

  def download_umls_notice
    puts 'UMLS file not found.'
    puts 'Download the US National Library of Medicine (NLM) Unified Medical Language System (UMLS) Full Release files'
    puts '  -> https://www.nlm.nih.gov/research/umls/licensedcontent/umlsknowledgesources.html'
    puts 'Install the metathesaurus with the following data sources:'
    puts '  CVX|CVX;ICD10CM|ICD10CM;ICD10PCS|ICD10PCS;ICD9CM|ICD9CM;LNC|LNC;MTHICD9|ICD9CM;RXNORM|RXNORM;SNOMEDCT_US|SNOMEDCT;CPT;HCPCS'
    puts 'After installation, copy `{install path}/META/MRCONSO.RRF` into your `./resources/terminology` folder, and rerun this task.'
  end

  desc 'post-process UMLS terminology file for translations'
  task :process_umls_translations, [] do |_t, _args|
    require 'find'
    puts 'Looking for `./resources/terminology/MRCONSO.RRF`...'
    input_file = Find.find('resources/terminology').find { |f| /MRCONSO.RRF$/ =~f }
    if input_file
      start = Time.now
      output_filename = 'resources/terminology/translations_umls.txt'
      output = File.open(output_filename, 'w:UTF-8')
      line = 0
      excluded = 0
      excluded_systems = Hash.new(0)
      begin
        entire_file = File.read(input_file)
        puts "Writing to #{output_filename}..."
        current_umls_concept = nil
        translation = Array.new(10)
        entire_file.split("\n").each do |l|
          row = l.split('|')
          line += 1
          include_code = false
          concept = row[0]
          if concept != current_umls_concept && !current_umls_concept.nil?
            output.write("#{translation.join('|')}\n") unless translation[1..-2].reject(&:nil?).length < 2
            translation = Array.new(10)
            current_umls_concept = concept
            translation[0] = current_umls_concept
          elsif current_umls_concept.nil?
            current_umls_concept = concept
            translation[0] = current_umls_concept
          end
          codeSystem = row[11]
          code = row[13]
          translation[9] = row[14]
          case codeSystem
          when 'SNOMEDCT_US'
            translation[1] = code if row[4] == 'PF' && ['FN', 'OAF'].include?(row[12])
          when 'LNC'
            translation[2] = code
          when 'ICD10CM'
            translation[3] = code if row[12] == 'PT'
          when 'ICD10PCS'
            translation[3] = code if row[12] == 'PT'
          when 'ICD9CM'
            translation[4] = code if row[12] == 'PT'
          when 'MTHICD9'
            translation[4] = code
          when 'RXNORM'
            translation[5] = code
          when 'CVX'
            translation[6] = code if ['PT', 'OP'].include?(row[12])
          when 'CPT'
            translation[7] = code if row[12] == 'PT'
          when 'HCPCS'
            translation[8] = code if row[12] == 'PT'
          when 'SRC'
            # 'SRC' rows define the data sources in the file
          else
            excluded_systems[codeSystem] += 1
          end
        end
      rescue Exception => e
        puts "Error at line #{line}"
        puts e.message
      end
      output.close
      puts "Processed #{line} lines."
      puts "Excluded code systems: #{excluded_systems}" unless excluded_systems.empty?
      finish = Time.now
      minutes = ((finish - start) / 60)
      seconds = (minutes - minutes.floor) * 60
      puts "Completed in #{minutes.floor} minute(s) #{seconds.floor} second(s)."
      puts 'Done.'
    else
      download_umls_notice
    end
  end

  desc 'Create ValueSet Validators'
  task :create_vs_validators, [:database, :type] do |_t, args|
    args.with_defaults(database: 'umls.db', type: 'bloom')
    validator_type = args.type.to_sym
    Inferno::Terminology.register_umls_db args.database
    Inferno::Terminology.load_valuesets_from_directory('resources', true)
    Inferno::Terminology.create_validators(validator_type)
  end
end
