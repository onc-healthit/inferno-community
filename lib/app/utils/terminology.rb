module Inferno
  class Terminology

    CODE_SYSTEMS = {
      'http://snomed.info/sct'=>'SNOMED',
      'http://loinc.org'=>'LOINC',
      'http://www.nlm.nih.gov/research/umls/rxnorm'=>'RXNORM',
      'http://hl7.org/fhir/sid/icd-10'=>'ICD10',
      'http://hl7.org/fhir/sid/icd-10-de'=>'ICD10',
      'http://hl7.org/fhir/sid/icd-10-nl'=>'ICD10',
      'http://hl7.org/fhir/sid/icd-10-us'=>'ICD10',
      'http://www.icd10data.com/icd10pcs'=>'ICD10',
      'http://hl7.org/fhir/sid/icd-9-cm'=>'ICD9',
      'http://hl7.org/fhir/sid/icd-9-cm/diagnosis'=>'ICD9',
      'http://hl7.org/fhir/sid/icd-9-cm/procedure'=>'ICD9',
      'http://hl7.org/fhir/sid/cvx'=>'CVX'
    }
    
    @@term_root = File.join('resources', 'terminology')

    @@loaded = false
    @@top_lab_code_descriptions = {}
    @@known_codes = {}
    @@core_snomed = {}
    @@common_ucum = []

    def self.reset
      @@loaded = false
      @@top_lab_code_descriptions = {}
      @@known_codes = {}
      @@core_snomed = {}
      @@common_ucum = []
    end
    private_class_method :reset

    def self.set_terminology_root(root)
      @@term_root = root
    end

    def self.load_terminology
      if !@@loaded
        begin
          # load the top lab codes
          filename = File.join(@@term_root,'terminology_loinc_2000.txt')
          raw = File.open(filename,'r:UTF-8',&:read)
          raw.split("\n").each do |line|
            row = line.split('|')
            @@top_lab_code_descriptions[row[0]] = row[1] if !row[1].nil?
          end
        rescue Exception => error
          FHIR.logger.error error
        end

        begin
          # load the known codes
          filename = File.join(@@term_root,'terminology_umls.txt')
          raw = File.open(filename,'r:UTF-8',&:read)
          raw.split("\n").each do |line|
            row = line.split('|')
            codeSystem = row[0]
            code = row[1]
            description = row[2]
            if @@known_codes[codeSystem]
              codeSystemHash = @@known_codes[codeSystem]
            else
              codeSystemHash = {}
              @@known_codes[codeSystem] = codeSystemHash
            end
            codeSystemHash[code] = description
          end
        rescue Exception => error
          FHIR.logger.error error
        end

        begin
          # load the core snomed codes
          @@known_codes['SNOMED'] = {} if @@known_codes['SNOMED'].nil?
          codeSystemHash = @@known_codes['SNOMED']
          filename = File.join(@@term_root,'terminology_snomed_core.txt')
          raw = File.open(filename,'r:UTF-8',&:read)
          raw.split("\n").each do |line|
            row = line.split('|')
            code = row[0]
            description = row[1]
            codeSystemHash[code] = description if codeSystemHash[code].nil?
            @@core_snomed[code] = description
          end   
        rescue Exception => error
          FHIR.logger.error error
        end

        begin
          # load common UCUM codes
          filename = File.join(@@term_root,'terminology_ucum.txt')
          raw = File.open(filename,'r:UTF-8',&:read)
          raw.split("\n").each do |code|
            @@common_ucum << code
          end
          @@common_ucum.uniq!
        rescue Exception => error
          FHIR.logger.error error
        end

        @@loaded = true
      end
    end

    def self.get_description(system,code)
      load_terminology
      if @@known_codes[system]
        @@known_codes[system][code]
      else
        nil
      end
    end

    def self.is_core_snomed?(code)
      load_terminology
      !@@core_snomed[code].nil?
    end

    def self.is_top_lab_code?(code)
      load_terminology
      !@@top_lab_code_descriptions[code].nil?
    end

    def self.is_known_ucum?(units)
      load_terminology
      @@common_ucum.include?(units)
    end

    def self.lab_description(code)
      load_terminology
      @@top_lab_code_descriptions[code]
    end
  end
end