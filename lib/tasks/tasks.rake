# frozen_string_literal: true

require 'fhir_client'
require 'pry'
require 'pry-byebug'
require 'csv'
require 'colorize'
require 'optparse'
require 'rubocop/rake_task'

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
  rescue StandardError => e
    $stdout.reopen(original_stdout)
    $stderr.reopen(original_stderr)
    raise e
  ensure
    $stdout.reopen(original_stdout)
    $stderr.reopen(original_stderr)
  end
  retval
end

# Removes indents from markdown for better printing
def unindent_markdown(markdown)
  return nil if markdown.nil?

  natural_indent = markdown.lines.collect { |l| l.index(/[^ ]/) }.select { |l| !l.nil? && l.positive? }.min || 0
  markdown.lines.map { |l| l[natural_indent..-1] || "\n" }.join.lstrip
end

def print_requests(result)
  result.request_responses.map do |req_res|
    req_res.response_code.to_s + ' ' + req_res.request_method.upcase + ' ' + req_res.request_url
  end
end

def execute(instance, sequences)
  client = FHIR::Client.for_testing_instance(instance)

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
        elsif instance.respond_to? key.to_s
          instance.send("#{key}=", val)
        end
      end
    end
    instance.save!
    sequence_instance = sequence.new(instance, client, false)
    sequence_result = nil

    suppress_output { sequence_result = sequence_instance.start }

    sequence_results << sequence_result

    checkmark = "\u2713"
    puts "\n" + sequence.sequence_name + " Sequence: \n"
    sequence_result.test_results.each do |result|
      print ' '
      if result.pass?
        print "#{checkmark.encode('utf-8')} pass".green
        print " - #{result.test_id} #{result.name}\n"
      elsif result.skip?
        print '* skip'.yellow
        print " - #{result.test_id} #{result.name}\n"
        puts "    Message: #{result.message}"
      elsif result.fail?
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
      elsif result.error?
        print 'X error'.magenta
        print " - #{result.test_id} #{result.name}\n"
        puts "    Message: #{result.message}"
        print_requests(result).map do |req|
          puts "      #{req}"
        end
        fails = true
      elsif result.omit?
        print '* omit'.light_black
        print " - #{result.test_id} #{result.name}\n"
        puts "    Message: #{result.message}"
      end
    end
    print "\n" + sequence.sequence_name + ' Sequence Result: '
    if sequence_result.pass?
      puts 'pass '.green + checkmark.encode('utf-8').green
    elsif sequence_result.fail?
      puts 'fail '.red + 'X'.red
      fails = true
    elsif sequence_result.error?
      puts 'error '.magenta + 'X'.magenta
      fails = true
    elsif sequence_result.skip?
      puts 'skip '.yellow + '*'.yellow
    end
    puts "---------------------------------------------\n"
  end

  failures_count = sequence_results.count(&:fail?).to_s
  passed_count = sequence_results.count(&:pass?).to_s
  print ' Result: ' + failures_count.red + ' failed, ' + passed_count.green + ' passed'
  if sequence_results.any?(&:skip?)
    skip_count = sequence_results.count(&:skip?).to_s
    print(', ' + skip_count.yellow + ' skipped')
  end
  if sequence_results.any?(&:error?)
    error_count = sequence_results.count(&:error?).to_s
    print(', ' + error_count.yellow + ' error')
  end

  puts "\n=============================================\n"

  return_value = 0
  return_value = 1 if fails

  return_value
end

def file_path(filename)
  return filename unless ENV['RACK_ENV'] == 'test'

  FileUtils.mkdir_p 'tmp'
  File.join('tmp', filename)
end

namespace :inferno do |_argv|
  # Exports a CSV containing the test metadata
  desc 'Generate List of All Tests'
  task :tests_to_csv, [:module, :group, :filename] do |_task, args|
    # Leaving for now, but we may want to consolodate under the XLS export
    # because that supports multi-line fields (e.g. descriptions) and our
    # intended audience for this feature will be opening the CSVs in Excel anyhow.
    # We could consider refactoring to allow either, but that doesn't have a high
    # priority at this point.
    Inferno.logger.warn 'Please use :tests_to_xls, which will replace this task'
    args.with_defaults(module: 'argonaut', group: 'active')
    args.with_defaults(filename: "#{args.module}_testlist.csv")
    inferno_module = Inferno::Module.get(args.module)
    sequences = inferno_module&.sequences
    if sequences.nil?
      puts "No sequence found for module: #{args.module}"
      exit
    end

    flat_tests = sequences.map do |klass|
      klass.tests(inferno_module).map do |test|
        test.metadata_hash.merge(
          sequence: klass.to_s,
          sequence_required: !klass.optional?
        )
      end
    end.flatten

    csv_out = CSV.generate do |csv|
      csv << ['Version', VERSION, 'Generated', Time.now]
      csv << ['', '', '', '', '']
      csv << ['Test ID', 'Reference', 'Sequence/Group', 'Test Name', 'Required?', 'Reference URI']
      flat_tests.each do |test|
        csv << [
          test[:test_id],
          test[:ref],
          test[:sequence].split('::').last,
          test[:name],
          test[:sequence_required] && test[:required],
          test[:url]
        ]
      end
    end

    filename = file_path(args.filename)

    File.write(filename, csv_out)
    Inferno.logger.info "Writing to #{filename}"
  end

  desc 'Generate a rich excel file'
  task :tests_to_xls, [:module, :test_set, :filename] do |_task, args|
    require 'rubyXL'
    require 'rubyXL/convenience_methods'
    args.with_defaults(module: 'onc_r4', test_set: 'test_procedure')
    args.with_defaults(filename: "#{args.module}_testlist.xlsx")

    workbook = RubyXL::Workbook.new
    worksheet = workbook.worksheets[0]

    ['Version', VERSION, '', 'Generated', Time.now.to_s].each_with_index do |value, index|
      worksheet.add_cell(0, index, value)
    end
    worksheet.change_row_italics(0, true)
    worksheet.add_cell(1, 0, '')

    ['Group',
     'Group Overview',
     '',
     'Test Case Name',
     'Test Case Description',
     'Test Case Details',
     '',
     'Test ID',
     'Test Name',
     'Test Link',
     'Required?',
     'Test Detail',
     '',
     'Test Procedure Reference'].each_with_index do |row_name, index|
      worksheet.add_cell(2, index, row_name)
    end

    worksheet.change_row_bold(2, true)
    test_module = Inferno::Module.get(args.module)
    test_set = test_module.test_sets[args.test_set.to_sym]
    row = 3

    test_set.groups.each do |group|
      group.test_cases.each do |test_case|
        test_case.sequence.tests(test_module).each do |test|
          [group.name,
           group.overview,
           '',
           test_case.title,
           test_case.description,
           unindent_markdown(test_case.sequence.details),
           '',
           "#{test_case.prefix}#{test.id}",
           test.name,
           test.link,
           (!test_case.sequence.optional? && !test.optional?).to_s,
           unindent_markdown(test.description),
           '',
           test.ref || ' '].each_with_index do |value, index|
            worksheet.add_cell(row, index, value)
          end
          row += 1
        end
      end
    end

    [30, 30, 3, 30, 90, 30, 3, 14, 100, 85, 9, 60, 3, 30].each_with_index do |width, index|
      worksheet.change_column_width(index, width)
    end

    Inferno.logger.info "Writing to #{args.filename}"
    workbook.write(args.filename)
  end

  desc 'Generate automated run script'
  task :generate_script, [:server, :module] do |_task, args|
    Inferno::StartupTasks.run

    sequences = []
    requires = []
    defines = []

    input = ''

    output = { server: args[:server], module: args[:module], arguments: {}, sequences: [] }

    instance = Inferno::TestingInstance.new(url: args[:server], selected_module: args[:module])
    instance.save!

    instance.module.sequences.each do |seq|
      unless input == 'a'
        print "\nInclude #{seq.sequence_name} (y/n/a)? "
        input = STDIN.gets.chomp
      end

      next unless ['a', 'y'].include? input

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
    Inferno::StartupTasks.run

    FHIR.logger.level = Logger::UNKNOWN
    sequences = []
    requires = []
    defines = []

    instance = Inferno::TestingInstance.new(url: args[:server], selected_module: args[:module])
    instance.save!

    instance.module.sequences.each do |seq|
      next unless args.extras.empty? || args.extras.include?(seq.sequence_name.split('Sequence')[0])

      seq.requires.each do |req|
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

  desc 'Execute sequence against a FHIR server'
  task :execute_batch, [:config] do |_task, args|
    Inferno::StartupTasks.run

    file = File.read(args.config)
    config = JSON.parse(file)

    instance = Inferno::TestingInstance.new(
      url: config['server'],
      selected_module: config['module'],
      initiate_login_uri: 'http://localhost:4568/launch',
      redirect_uris: 'http://localhost:4568/redirect'
    )
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
        elsif instance.respond_to? key.to_s
          instance.send("#{key}=", val)
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

  desc 'Generate Tests'
  task :generate, [:generator, :path, :add_to_config] do |_t, args|
    args.with_defaults(add_to_config: 'true')
    require_relative("../../generator/#{args.generator}/#{args.generator}_generator")
    generator_class = Inferno::Generator::Base.subclasses.first do |c|
      c.name.demodulize.downcase.start_with?(args.generator)
    end

    generator = generator_class.new(args.path, args.extras)
    generator.run
    if args.add_to_config == 'true'
      ConfigManager.new('config.yml').tap do |cm|
        cm.add_modules(args.path)
        cm.write_to_file('config.yml')
      end
    end
  end
end

namespace :terminology do |_argv|
  TEMP_DIR = 'tmp/terminology'
  desc 'download and execute UMLS terminology data'
  task :download_umls, [:username, :password] do |_t, args|
    # Adapted from python https://github.com/jmandel/umls-bloomer/blob/master/01-download.py
    default_target_file = 'https://download.nlm.nih.gov/umls/kss/2019AB/umls-2019AB-full.zip'

    FileUtils.mkdir_p(TEMP_DIR)

    puts 'Getting Login Page'
    response = RestClient.get default_target_file
    # Get the final redirection URL
    login_page = response.history.last.headers[:location]
    action_base = login_page.split('/cas/')[0]
    action_path = response.body.split('form id="fm1" action="')[1].split('"')[0]
    execution = response.body.split('name="execution" value="')[1].split('"')[0]

    begin
      puts 'Getting Download Link'
      RestClient::Request.execute(method: :post,
                                  url: action_base + action_path,
                                  payload: {
                                    username: args.username,
                                    password: args.password,
                                    execution: execution,
                                    _eventId: 'submit'
                                  },
                                  max_redirects: 0)
    rescue RestClient::ExceptionWithResponse => e
      follow_redirect(e.response.headers[:location], e.response.headers[:set_cookie])
    end
    puts 'Finished Downloading!'
  end

  def follow_redirect(location, cookie = nil)
    return unless location

    size = 0
    percent = 0
    current_percent = 0
    File.open(File.join(TEMP_DIR, 'umls.zip'), 'w') do |f|
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

  desc 'unzip umls zip'
  task :unzip_umls, [:umls_zip] do |_t, args|
    args.with_defaults(umls_zip: File.join(TEMP_DIR, 'umls.zip'))
    destination = File.join(TEMP_DIR, 'umls')
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
    args.with_defaults(my_config: 'inferno.prop')
    jre_version = if !(/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM).nil?
                    'windows64'
                  elsif !(/darwin/ =~ RUBY_PLATFORM).nil?
                    'macos'
                  else
                    'linux'
                  end
    puts "#{jre_version} system detected"
    config_file = File.join(Dir.pwd, 'resources', 'terminology', args.my_config)
    output_dir = File.join(Dir.pwd, TEMP_DIR, 'umls_subset')
    FileUtils.mkdir(output_dir)
    puts "Using #{config_file}"
    Dir.chdir(Dir[File.join(Dir.pwd, TEMP_DIR, '/umls/20*')][0]) do
      puts Dir.pwd
      Dir['lib/*.jar'].each do |jar|
        File.chmod(0o555, jar)
      end
      Dir["jre/#{jre_version}/bin/*"].each do |file|
        File.chmod(0o555, file)
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
      unless output
        puts 'MetamorphoSys run failed'
        # The cwd at this point is 2 directories above where umls_subset is, so we have to navigate up to it
        FileUtils.remove_dir(File.join(Dir.pwd, '..', '..', 'umls_subset')) if File.directory?(File.join(Dir.pwd, '..', '..', 'umls_subset'))
        exit 1
      end
    end
    puts 'done'
  end

  desc 'cleanup terminology files'
  task :cleanup, [] do |_t, _args|
    puts "removing terminology files in #{TEMP_DIR}"
    FileUtils.remove_dir TEMP_DIR
  end

  desc 'post-process UMLS terminology file'
  task :process_umls, [] do |_t, _args|
    require 'find'
    require 'csv'
    puts 'Looking for `./tmp/terminology/MRCONSO.RRF`...'
    input_file = Find.find(TEMP_DIR).find { |f| /MRCONSO.RRF$/ =~f }
    if input_file
      start = Time.now
      output_filename = File.join(TEMP_DIR, 'terminology_umls.txt')
      output = File.open(output_filename, 'w:UTF-8')
      line = 0
      excluded = 0
      excluded_systems = Hash.new(0)
      begin
        puts "Writing to #{output_filename}..."
        CSV.foreach(input_file, headers: false, col_sep: '|', quote_char: "\x00") do |row|
          line += 1
          include_code = false
          code_system = row[11]
          code = row[13]
          description = row[14]
          case code_system
          when 'SNOMEDCT_US'
            code_system = 'SNOMED'
            include_code = (row[4] == 'PF' && ['FN', 'OAF'].include?(row[12]))
          when 'LNC'
            code_system = 'LOINC'
            include_code = true
          when 'ICD10CM'
            code_system = 'ICD10'
            include_code = (row[12] == 'PT')
          when 'ICD10PCS'
            code_system = 'ICD10'
            include_code = (row[12] == 'PT')
          when 'ICD9CM'
            code_system = 'ICD9'
            include_code = (row[12] == 'PT')
          when 'CPT'
            include_code = (row[12] == 'PT')
          when 'HCPCS'
            include_code = (row[12] == 'PT')
          when 'MTHICD9'
            code_system = 'ICD9'
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
            excluded_systems[code_system] += 1
          end
          if include_code
            output.write("#{code_system}|#{code}|#{description}\n")
          else
            excluded += 1
          end
        end
      rescue StandardError => e
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
    puts 'After installation, copy `{install path}/META/MRCONSO.RRF` into your `./tmp/terminology` folder, and rerun this task.'
  end

  desc 'post-process UMLS terminology file for translations'
  task :process_umls_translations, [] do |_t, _args|
    require 'find'
    puts 'Looking for `./tmp/terminology/MRCONSO.RRF`...'
    input_file = Find.find(File.join(TEMP_DIR, 'terminology')).find { |f| /MRCONSO.RRF$/ =~f }
    if input_file
      start = Time.now
      output_filename = File.join(TEMP_DIR, 'translations_umls.txt')
      output = File.open(output_filename, 'w:UTF-8')
      line = 0
      excluded_systems = Hash.new(0)
      begin
        entire_file = File.read(input_file)
        puts "Writing to #{output_filename}..."
        current_umls_concept = nil
        translation = Array.new(10)
        entire_file.split("\n").each do |l|
          row = l.split('|')
          line += 1
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
          code_system = row[11]
          code = row[13]
          translation[9] = row[14]
          case code_system
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
            excluded_systems[code_system] += 1
          end
        end
      rescue StandardError => e
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
    args.with_defaults(database: File.join(TEMP_DIR, 'umls.db'), type: 'bloom')
    validator_type = args.type.to_sym
    Inferno::Terminology.register_umls_db args.database
    Inferno::Terminology.load_valuesets_from_directory(Inferno::Terminology::PACKAGE_DIR, true)
    Inferno::Terminology.create_validators(type: validator_type)
  end

  desc 'Create only non-UMLS validators'
  task :create_non_umls_vs_validators, [:module, :minimum_binding_strength] do |_t, args|
    args.with_defaults(type: 'bloom',
                       module: :all,
                       minimum_binding_strength: 'example')
    validator_type = args.type.to_sym
    Inferno::Terminology.load_valuesets_from_directory(Inferno::Terminology::PACKAGE_DIR, true)
    Inferno::Terminology.create_validators(type: validator_type,
                                           selected_module: args.module,
                                           minimum_binding_strength: args.minimum_binding_strength,
                                           include_umls: false)
  end

  desc 'Create ValueSet Validators for a given module'
  task :create_module_vs_validators, [:module, :minimum_binding_strength] do |_t, args|
    args.with_defaults(module: 'all', minimum_binding_strength: 'example')
    Inferno::Terminology.register_umls_db File.join(TEMP_DIR, 'umls.db')
    Inferno::Terminology.load_valuesets_from_directory(Inferno::Terminology::PACKAGE_DIR, true)
    Inferno::Terminology.create_validators(type: :bloom,
                                           selected_module: args.module,
                                           minimum_binding_strength: args.minimum_binding_strength)
  end

  desc 'Number of codes in ValueSet'
  task :codes_in_valueset, [:vs] do |_t, args|
    Inferno::Terminology.register_umls_db File.join(TEMP_DIR, 'umls.db')
    Inferno::Terminology.load_valuesets_from_directory(Inferno::Terminology::PACKAGE_DIR, true)
    vs = Inferno::Terminology.known_valuesets[args.vs]
    puts vs&.valueset&.count
  end

  desc 'Expand and Save ValueSet to a file'
  task :expand_valueset_to_file, [:vs, :filename, :type] do |_t, args|
    Inferno::Terminology.register_umls_db File.join(TEMP_DIR, 'umls.db')
    Inferno::Terminology.load_valuesets_from_directory(Inferno::Terminology::PACKAGE_DIR, true)
    vs = Inferno::Terminology.known_valuesets[args.vs]
    if args.type == 'json'
      File.open("#{args.filename}.json", 'wb') { |f| f << vs.expansion_as_fhir_valueset.to_json }
    else
      Inferno::Terminology.save_to_file(vs.valueset, args.filename, args.type.to_sym)
    end
  end

  desc 'Download FHIR Package'
  task :download_package, [:package, :location] do |_t, args|
    Inferno::FHIRPackageManager.get_package(args.package, args.location)
  end

  desc 'Download Terminology from FHIR Package'
  task :download_program_terminology do |_t, _args|
    Inferno::Terminology.load_fhir_r4
    Inferno::Terminology.load_fhir_expansions
    Inferno::Terminology.load_us_core
  end

  desc 'Check if the code is in the specified ValueSet.  Omit the ValueSet to check against CodeSystem'
  task :check_code, [:code, :system, :valueset] do |_t, args|
    args.with_defaults(system: nil, valueset: nil)
    code_display = args.system ? "#{args.system}|#{args.code}" : args.code.to_s
    if Inferno::Terminology.validate_code(code: args.code, system: args.system, valueset_url: args.valueset)
      in_system = 'is in'
      symbol = "\u2713".encode('utf-8').to_s.green
    else
      in_system = 'is not in'
      symbol = 'X'.red
    end
    system_checked = args.valueset || args.system

    puts "#{symbol} #{code_display} #{in_system} #{system_checked}"
  end
end

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['--display-cop-names']
end
