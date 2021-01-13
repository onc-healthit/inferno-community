# frozen_string_literal: true

require 'sqlite3'
require 'date'
require_relative 'bcp_13'
require_relative 'bcp47'
require_relative 'codesystem'
require_relative 'fhir_package_manager'

module Inferno
  class Terminology
    class ValueSet
      # STU3 ValueSets located at: http://hl7.org/fhir/stu3/terminologies-valuesets.html
      # STU3 ValueSet Resource: http://hl7.org/fhir/stu3/valueset.html
      #
      # snomed in umls: https://www.nlm.nih.gov/research/umls/Snomed/snomed_represented.html

      # The UMLS Database
      attr_accessor :db
      # The FHIR::Model Representation of the ValueSet
      attr_accessor :valueset_model

      # The ValueSet Authority
      attr_accessor :vsa

      # Flag to say "use the provided expansion" when processing the valueset
      attr_accessor :use_expansions

      # UMLS Vocabulary: https://www.nlm.nih.gov/research/umls/sourcereleasedocs/index.html
      SAB = {
        'http://www.nlm.nih.gov/research/umls/rxnorm' => 'RXNORM',
        'http://loinc.org' => 'LNC',
        'http://snomed.info/sct' => 'SNOMEDCT_US',
        'http://www.icd10data.com/icd10pcs' => 'ICD10PCS',
        'http://hl7.org/fhir/sid/cvx' => 'CVX',
        'http://hl7.org/fhir/sid/icd-10-cm' => 'ICD10CM',
        'http://hl7.org/fhir/sid/icd-9-cm' => 'ICD9CM',
        'http://unitsofmeasure.org' => 'NCI_UCUM',
        'http://nucc.org/provider-taxonomy' => 'NUCCPT',
        'http://www.ama-assn.org/go/cpt' => 'CPT',
        'urn:oid:2.16.840.1.113883.6.285' => 'HCPCS'
      }.freeze

      CODE_SYS = {
        'urn:ietf:bcp:13' => -> { BCP13.code_set },
        'urn:ietf:bcp:47' => ->(filter = nil) { Inferno::BCP47.code_set(filter) },
        'http://ihe.net/fhir/ValueSet/IHE.FormatCode.codesystem' => -> { Inferno::Terminology.known_valuesets['http://hl7.org/fhir/ValueSet/formatcodes'].valueset },
        'https://www.usps.com/' => -> { Inferno::Terminology.known_valuesets['http://hl7.org/fhir/us/core/ValueSet/us-core-usps-state'].valueset }
      }.freeze

      # https://www.nlm.nih.gov/research/umls/knowledge_sources/metathesaurus/release/attribute_names.html
      FILTER_PROP = {
        'CLASSTYPE' => 'LCN',
        'DOC' => 'Doc',
        'SCALE_TYP' => 'LOINC_SCALE_TYP'
      }.freeze

      def initialize(database, use_expansions = true)
        @db = database
        @use_expansions = use_expansions
      end

      # The ValueSet [Set]
      def valueset
        return @valueset if @valueset

        if @use_expansions
          process_with_expansions
        else
          process_valueset
        end
      end

      # Read the desired valueset from a JSON file
      #
      # @param filename [String] the name of the file
      def read_valueset(filename)
        @valueset_model = FHIR::Json.from_json(File.read(filename))
      end

      def code_system_set(code_system)
        filter_code_set(code_system)
      end

      def expansion_as_fhir_valueset
        expansion_backbone = FHIR::ValueSet::Expansion.new
        expansion_backbone.timestamp = DateTime.now.strftime('%Y-%m-%dT%H:%M:%S%:z')
        expansion_backbone.contains = valueset.map do |code|
          FHIR::ValueSet::Expansion::Contains.new(system: code[:system], code: code[:code])
        end
        expansion_backbone.total = expansion_backbone.contains.length
        expansion_valueset = @valueset_model.deep_dup # Make a copy so that the original definition is left intact
        expansion_valueset.expansion = expansion_backbone
        expansion_valueset
      end

      # Return the url of the valueset
      def url
        @valueset_model.url
      end

      # Return the number of codes in the valueset
      def count
        @valueset.length
      end

      def included_code_systems
        @valueset_model.compose.include.map(&:system).compact.uniq
      end

      # Delegates to process_expanded_valueset if there's already an expansion
      # Otherwise it delegates to process_valueset to do the expansion
      def process_with_expansions
        valueset_toocostly = @valueset_model&.expansion&.extension&.find { |vs| vs.url == 'http://hl7.org/fhir/StructureDefinition/valueset-toocostly' }&.value
        valueset_unclosed = @valueset_model&.expansion&.extension&.find { |vs| vs.url == 'http://hl7.org/fhir/StructureDefinition/valueset-unclosed' }&.value
        if @valueset_model&.expansion&.contains
          # This is moved into a nested clause so we can tell in the debug statements which path we're taking
          if valueset_toocostly || valueset_unclosed
            Inferno.logger.debug("ValueSet too costly or unclosed: #{url}")
            process_valueset
          else
            Inferno.logger.debug("Processing expanded valueset: #{url}")
            process_expanded_valueset
          end
        else
          Inferno.logger.debug("Processing composed valueset: #{url}")
          process_valueset
        end
      end

      # Creates the whole valueset
      #
      # Creates a [Set] representing the valueset
      def process_valueset
        Inferno.logger.debug "Processing #{@valueset_model.url}"
        include_set = Set.new
        @valueset_model.compose.include.each do |include|
          # Cumulative of each include
          include_set.merge(get_code_sets(include))
        end
        @valueset_model.compose.exclude.each do |exclude|
          # Remove excluded codes
          include_set.subtract(get_code_sets(exclude))
        end
        @valueset = include_set
      end

      def process_expanded_valueset
        include_set = Set.new
        @valueset_model.expansion.contains.each do |contain|
          include_set.add(system: contain.system, code: contain.code)
        end
        @valueset = include_set
      end

      # Checks if the provided code is in the valueset
      #
      # Codes should be provided as a [Hash] type object
      #
      # e.g. {system: 'http://loinc.org', code: '1234'}
      #
      # @param [Hash] code the code to evaluate
      # @return [Boolean]
      def contains_code?(code)
        @valueset.include? code
      end

      def generate_bloom
        require 'bloomer'
        @bf = Bloomer::Scalable.new # (100_000, 0.00001)
        valueset.each do |cc|
          @bf.add("#{cc[:system]}|#{cc[:code]}")
        end
        @bf
      end

      # Saves the valueset bloomfilter to a msgpack file
      #
      # @param [String] filename the name of the file
      def save_bloom_to_file(filename = "resources/validators/bloom/#{(URI(url).host + URI(url).path).gsub(%r{[./]}, '_')}.msgpack")
        generate_bloom unless @bf
        bloom_file = File.new(filename, 'wb')
        bloom_file.write(@bf.to_msgpack) unless @bf.nil?
        filename
      end

      # Saves the valueset to a csv
      # @param [String] filename the name of the file
      def save_csv_to_file(filename = "resources/validators/csv/#{(URI(url).host + URI(url).path).gsub(%r{[./]}, '_')}.csv")
        CSV.open(filename, 'wb') do |csv|
          valueset.each do |code|
            csv << [code[:system], code[:code]]
          end
        end
      end

      # Load a code system from a file
      #
      # @param [String] filename the file containing the code system JSON
      def self.load_system(filename)
        cs = FHIR::Json.from_json(File.read(filename))
        cs_set = Set.new
        load_codes = lambda do |concept|
          concept.each do |concept_code|
            cs_set.add(system: cs.url, code: concept_code.code)
            load_codes.call(concept_code.concept) unless concept_code.concept.empty?
          end
        end
        load_codes.call(cs.concept)
        cs_set
      end

      private

      # Get all the code systems from within an include/exclude and return the set representing the intersection
      #
      # See: http://hl7.org/fhir/stu3/valueset.html#compositions
      #
      # @param [ValueSet::Compose::Include] vscs the FHIR ValueSet include or exclude
      def get_code_sets(vscs)
        intersection_set = nil

        # Get Concepts
        if !vscs.concept.empty?
          intersection_set = Set.new
          vscs.concept.each do |concept|
            intersection_set.add(system: vscs.system, code: concept.code)
          end
          # Filter based on the filters. Note there cannot be both concepts and filters within a single include/exclude
        elsif !vscs.filter.empty?
          intersection_set = filter_code_set(vscs.system, vscs.filter.first)
          vscs.filter.drop(1).each do |filter|
            intersection_set = intersection_set.intersection(filter_code_set(vscs.system, filter))
          end
          # Import whole code systems if given
        elsif vscs.system
          intersection_set = filter_code_set(vscs.system)
        end

        unless vscs.valueSet.empty?
          # If no concepts or filtered systems were present and already created the intersection_set
          im_val_set = import_valueset(vscs.valueSet.first)
          vscs.valueSet.drop(1).each do |im_val|
            im_val_set = im_val_set.intersection(im_val)
          end
          intersection_set = intersection_set.nil? ? im_val_set : intersection_set.intersection(im_val_set)
        end
        intersection_set
      end

      # Provides a codeset based on the system and filters provided
      # @param [String] system the code system url
      # @param [FHIR::ValueSet::Compose::Include::Filter] filter the filter object
      # @return [Set] the filtered set of codes
      def filter_code_set(system, filter = nil, _version = nil)
        fhir_codesystem = File.join(Terminology::PACKAGE_DIR, FHIRPackageManager.encode_name(system).to_s + '.json')
        if CODE_SYS.include? system
          Inferno.logger.debug "  loading #{system} codes..."
          return filter.nil? ? CODE_SYS[system].call : CODE_SYS[system].call(filter)
        elsif File.exist?(fhir_codesystem)
          if SAB[system].nil?
            fhir_cs = Inferno::Terminology::Codesystem
              .new(FHIR::Json.from_json(File.read(fhir_codesystem)))

            raise UnknownCodeSystemException, system if fhir_cs.codesystem_model.concept.empty?

            return fhir_cs.filter_codes(filter)
          end
        end

        filter_clause = lambda do |filter|
          where = +''
          if filter.op == 'in'
            col = filter.property
            vals = filter.value.split(',')
            where << "( #{col} = '#{vals[0]}'"
            # Remove the first element after we've used it
            vals.shift
            vals.each do |val|
              where << " OR #{col} = '#{val}' "
            end
            where << ')'
          elsif filter.op == '='
            col = filter.property
            where << "#{col} = '#{filter.value}'"
          else
            Inferno.logger.debug "Cannot handle filter operation: #{filter.op}"
          end
          where
        end

        filtered_set = Set.new
        raise FilterOperationException, filter&.op unless ['=', 'in', 'is-a', nil].include? filter&.op
        raise UnknownCodeSystemException, system if SAB[system].nil?

        if filter.nil?
          @db.execute("SELECT code FROM mrconso WHERE SAB = '#{SAB[system]}'") do |row|
            filtered_set.add(system: system, code: row[0])
          end
        elsif ['=', 'in', nil].include? filter&.op
          if FILTER_PROP[filter.property]
            @db.execute("SELECT code FROM mrsat WHERE SAB = '#{SAB[system]}' AND ATN = '#{fp_self(filter.property)}' AND ATV = '#{fp_self(filter.value)}'") do |row|
              filtered_set.add(system: system, code: row[0])
            end
          else
            @db.execute("SELECT code FROM mrconso WHERE SAB = '#{SAB[system]}' AND #{filter_clause.call(filter)}") do |row|
              filtered_set.add(system: system, code: row[0])
            end
          end
        elsif filter&.op == 'is-a'
          filtered_set = filter_is_a(system, filter)
        else
          throw FilterOperationException(filter&.op)
        end
        filtered_set
      end

      # Imports the ValueSet with the provided URL from the known local ValueSet Authority
      #
      # @param [Object] url the url of the desired valueset
      # @return [Set] the imported valueset
      def import_valueset(desired_url)
        @vsa.get_valueset(desired_url).valueset
      end

      # Filters UMLS codes for "is-a" filters
      #
      # @param [String] system The code system url
      # @param [FHIR::ValueSet::Compose::Include::Filter] filter the filter object
      # @return [Set] the filtered codes
      def filter_is_a(system, filter)
        children = {}
        find_children = lambda do |_parent, system|
          @db.execute("SELECT c1.code, c2.code
          FROM mrrel r
            JOIN mrconso c1 ON c1.aui=r.aui1
            JOIN mrconso c2 ON c2.aui=r.aui2
          WHERE r.rel='CHD' AND r.SAB= '#{SAB[system]}'") do |row|
            children[row[0]] ||= []
            children[row[0]] << row[1]
          end
        end
        # Get all the children/parent hierarchy
        find_children.call(filter.value, system)

        desired_children = Set.new
        subsume = lambda do |parent|
          # Only execute if we haven't processed this parent yet
          par = { system: system, code: parent }
          unless desired_children.include? par
            desired_children.add(system: system, code: parent)
            children[parent]&.each do |child|
              subsume.call(child)
            end
          end
        end
        subsume.call(filter.value)
        desired_children
      end

      # fp_self is short for filter_prop_or_self
      # @param [String] prop The property name
      # @return [String] either the value from FILTER_PROP for that key, or prop if that key isn't in FILTER_PROP
      def fp_self(prop)
        FILTER_PROP[prop] || prop
      end

      class FilterOperationException < StandardError
        def initialize(filter_op)
          super("Cannot Handle Filter Operation: #{filter_op}")
        end
      end

      class UnknownCodeSystemException < StandardError
        def initialize(code_system)
          super("Unknown Code System: #{code_system}")
        end
      end
    end
  end
end
