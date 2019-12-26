# frozen_string_literal: true

require_relative 'valueset'
module Inferno
  class Terminology
    CODE_SYSTEMS = {
      'http://snomed.info/sct' => 'SNOMED',
      'http://loinc.org' => 'LOINC',
      'http://www.nlm.nih.gov/research/umls/rxnorm' => 'RXNORM',
      'http://hl7.org/fhir/sid/icd-10' => 'ICD10',
      'http://hl7.org/fhir/sid/icd-10-de' => 'ICD10',
      'http://hl7.org/fhir/sid/icd-10-nl' => 'ICD10',
      'http://hl7.org/fhir/sid/icd-10-us' => 'ICD10',
      'http://www.icd10data.com/icd10pcs' => 'ICD10',
      'http://hl7.org/fhir/sid/icd-9-cm' => 'ICD9',
      'http://hl7.org/fhir/sid/icd-9-cm/diagnosis' => 'ICD9',
      'http://hl7.org/fhir/sid/icd-9-cm/procedure' => 'ICD9',
      'http://hl7.org/fhir/sid/cvx' => 'CVX'
    }.freeze

    @known_valuesets = {}
    @valueset_ids = nil
    @loaded_code_systems = nil

    @loaded_validators = {}
    class << self; attr_reader :loaded_validators, :known_valuesets; end

    def self.load_valuesets_from_directory(directory, include_subdirectories = false)
      directory += '/**/' if include_subdirectories
      valueset_files = Dir["#{directory}/ValueSet*"]
      valueset_files.each do |vs_file|
        add_valueset_from_file(vs_file)
      end
    end

    def self.create_validators(type)
      validators = []
      case type
      when :bloom
        root_dir = 'resources/terminology/validators/bloom'
        FileUtils.mkdir_p(root_dir) unless File.directory?(root_dir)
        @known_valuesets.each do |k, vs|
          next if (k == 'http://fhir.org/guides/argonaut/ValueSet/argo-codesystem') || (k == 'http://fhir.org/guides/argonaut/ValueSet/languages') || (k == 'http://hl7.org/fhir/us/core/ValueSet/simple-language')

          Inferno.logger.debug "Processing #{k}"
          filename = "#{root_dir}/#{(URI(vs.url).host + URI(vs.url).path).gsub(%r{[./]}, '_')}.msgpack"
          save_bloom_to_file(vs.valueset, filename)
          validators << { url: k, file: File.basename(filename), count: vs.count, type: 'bloom' }
        end
        vs = Inferno::Terminology::Valueset.new(@db)
        Inferno::Terminology::Valueset::SAB.each do |k, _v|
          Inferno.logger.debug "Processing #{k}"
          cs = vs.code_system_set(k)
          filename = "#{root_dir}/#{bloom_file_name(k)}.msgpack"
          save_bloom_to_file(cs, filename)
          validators << { url: k, file: File.basename(filename), count: cs.length, type: 'bloom' }
        end
        # Write manifest for loading later
        File.write("#{root_dir}/manifest.yml", validators.to_yaml)
      when :csv
        root_dir = 'resources/terminology/validators/csv'
        FileUtils.mkdir_p(root_dir) unless File.directory?(root_dir)
        @known_valuesets.each do |k, vs|
          next if (k == 'http://fhir.org/guides/argonaut/ValueSet/argo-codesystem') || (k == 'http://fhir.org/guides/argonaut/ValueSet/languages')

          Inferno.logger.debug "Processing #{k}"
          filename = "#{root_dir}/#{bloom_file_name(vs.url)}.csv"
          save_csv_to_file(vs.valueset, filename)
          validators << { url: k, file: File.basename(filename), count: vs.count, type: 'csv' }
        end
        vs = Inferno::Terminology::Valueset.new(@db)
        Inferno::Terminology::Valueset::SAB.each do |k, _v|
          Inferno.logger.debug "Processing #{k}"
          cs = vs.code_system_set(k)
          filename = "#{root_dir}/#{bloom_file_name(k)}.csv"
          save_csv_to_file(cs, filename)
          validators << { url: k, file: File.basename(filename), count: cs.length, type: 'csv' }
        end
        # Write manifest for loading later
        File.write("#{root_dir}/manifest.yml", validators.to_yaml)
      else
        raise 'Unknown Validator Type!'
      end
    end

    # Saves the valueset bloomfilter to a msgpack file
    #
    # @param [String] filename the name of the file
    def self.save_bloom_to_file(codeset, filename)
      require 'bloomer'
      bf = Bloomer::Scalable.new
      codeset.each do |cc|
        bf.add("#{cc[:system]}|#{cc[:code]}")
      end
      File.write(filename, bf.to_msgpack) unless bf.nil?
    end

    # Saves the valueset to a csv
    # @param [String] filename the name of the file
    def self.save_csv_to_file(codeset, filename)
      CSV.open(filename, 'wb') do |csv|
        codeset.each do |code|
          csv << [code[:system], code[:code]]
        end
      end
    end

    def self.register_umls_db(database)
      @db = SQLite3::Database.new database
    end

    def self.add_valueset_from_file(vs_file)
      vs = Inferno::Terminology::Valueset.new(@db)
      vs.read_valueset(vs_file)
      vs.vsa = self
      @known_valuesets[vs.url] = vs
      vs
    end

    # Load the validators into FHIR::Models
    def self.load_validators(directory = 'resources/terminology/validators/bloom')
      manifest_file = "#{directory}/manifest.yml"
      return unless File.file? manifest_file

      validators = YAML.load_file("#{directory}/manifest.yml")
      validators.each do |validator|
        bfilter = Bloomer::Scalable.from_msgpack(File.open("#{directory}/#{validator[:file]}").read)
        validate_fn = lambda do |coding|
          probe = "#{coding['system']}|#{coding['code']}"
          bfilter.include? probe
        end
        # Register the validators with FHIR Models for validation
        FHIR::DSTU2::StructureDefinition.validates_vs(validator[:url], &validate_fn)
        FHIR::StructureDefinition.validates_vs(validator[:url], &validate_fn)
        @loaded_validators[validator[:url]] = validator[:count]
      end
    end

    def self.get_valueset(url)
      @known_valuesets[url]&.valueset || raise(UnknownValueSetException, url)
    end

    def self.get_valueset_by_id(id)
      unless @valueset_ids
        @valueset_ids = {}
        @known_valuesets.each_pair do |k, v|
          @valueset_ids[v&.valueset_model&.id] = k
        end
      end
      @known_valuesets[@valueset_ids[id]] || raise(UnknownValueSetException, id)
    end

    def self.bloom_file_name(codesystem)
      uri = URI(codesystem)
      if uri.host && uri.port
        return (uri.host + uri.path).gsub(%r{[./]}, '_')
      else
        return codesystem.gsub(%r{[.\W]}, '_')
      end
    end

    def self.loaded_code_systems
      @loaded_code_systems ||= @known_valuesets.flat_map do |_, vs|
        vs.included_code_systems.uniq
      end.uniq.compact
    end

    class UnknownValueSetException < StandardError
      def initialize(value_set)
        super("Unknown ValueSet: #{value_set}")
      end
    end
  end
end
