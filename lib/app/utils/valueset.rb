# frozen_string_literal: true

require 'sqlite3'
module Inferno
  class Terminology
    class Valueset
      # STU3 Valuesets located at: http://hl7.org/fhir/stu3/terminologies-valuesets.html
      # STU3 Valueset Resource: http://hl7.org/fhir/stu3/valueset.html
      #
      # snomed in umls: https://www.nlm.nih.gov/research/umls/Snomed/snomed_represented.html

      # The UMLS Database
      attr_accessor :db
      # The FHIR::Model Representation of the ValueSet
      attr_accessor :valueset_model

      # The ValueSet Authority
      attr_accessor :vsa

      # UMLS Vocabulary: https://www.nlm.nih.gov/research/umls/sourcereleasedocs/index.html
      SAB = {
        'http://www.nlm.nih.gov/research/umls/rxnorm' => 'RXNORM',
        'http://loinc.org' => 'LNC',
        'http://snomed.info/sct' => 'SNOMEDCT_US',
        'http://www.icd10data.com/icd10pcs' => 'ICD10CM',
        'http://unitsofmeasure.org' => 'NCI_UCUM',
        'http://hl7.org/fhir/ndfrt' => 'NDFRT',
        'http://nucc.org/provider-taxonomy' => 'NUCCPT',
        'http://www.ama-assn.org/go/cpt' => 'CPT'
      }.freeze

      CODE_SYS = {
        'http://hl7.org/fhir/v3/Ethnicity' => 'resources/misc_valuesets/CodeSystem-v3-Ethnicity.json',
        'http://hl7.org/fhir/v3/Race' => 'resources/misc_valuesets/CodeSystem-v3-Race.json',
        'http://hl7.org/fhir/condition-category' => 'resources/misc_valuesets/CodeSystem-condition-category.json'
      }.freeze

      def initialize(database)
        @db = database
      end

      # The ValueSet [Set]
      def valueset
        @valueset || process_valueset
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

      # Return the url of the valueset
      def url
        @valueset_model.url
      end

      # Return the number of codes in the valueset
      def count
        @valueset.length
      end

      # Creates the whole valueset
      #
      # Creates a [Set] representing the valueset
      def process_valueset
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

      def generate_array
        x = []
        get_valueset_rows valueset do |row|
          x << row[0]
        end
        x
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
        File.write(filename, @bf.to_msgpack) unless @bf.nil?
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

      private

      # Get all the code systems from within an include/exclude and return the set representing the intersection
      #
      # See: http://hl7.org/fhir/stu3/valueset.html#compositions
      #
      # @param [ValueSet::Compose::Include] vscs the FHIR Valueset include or exclude
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
            puts "Cannot handle filter operation: #{filter.op}"
          end
          where
        end

        filtered_set = Set.new
        if CODE_SYS.include? system
          puts "loading #{system} codes..."
          return load_code_system(system)
        end
        raise "Can't handle #{filter&.op}" unless ['=', 'in', 'is-a', nil].include? filter&.op
        raise UnknownCodeSystemException, system if SAB[system].nil?

        if filter.nil?
          @db.execute("SELECT code FROM mrconso WHERE SAB = '#{SAB[system]}'") do |row|
            filtered_set.add(system: system, code: row[0])
          end
        elsif ['=', 'in', nil].include? filter&.op
          @db.execute("SELECT code FROM mrconso WHERE SAB = '#{SAB[system]}' AND #{filter_clause.call(filter)}") do |row|
            filtered_set.add(system: system, code: row[0])
          end
        elsif filter&.op == 'is-a'
          filtered_set = filter_is_a(system, filter)
        end
        filtered_set
      end

      # Load a code system from a file
      #
      # @param [String] system the name of the code system
      def load_code_system(system)
        # TODO: Generalize this
        cs = FHIR::Json.from_json(File.read(CODE_SYS[system]))
        cs_set = Set.new
        load_codes = lambda do |concept|
          concept.each do |concept_code|
            cs_set.add(system: system, code: concept_code.code)
            load_codes.call(concept_code.concept) unless concept_code.concept.empty?
          end
        end
        load_codes.call(cs.concept)
        cs_set
      end

      # Imports the ValueSet with the provided URL from the known local ValueSet Authority
      #
      # @param [Object] url the url of the desired valueset
      # @return [Set] the imported valueset
      def import_valueset(url)
        @vsa.get_valueset(url)
      end

      # Filters UMLS codes for "is-a" filters
      #
      # @param [String] system The code system url
      # @param [FHIR::ValueSet::Compose::Include::Filter] filter the filter object
      # @return [Set] the filtered codes
      def filter_is_a(system, filter)
        children = {}
        find_children = lambda do |_parent, system|
          puts 'getting children...'
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
