sequence_dir = './lib/app/modules'
tests_dir = './test/sequence'

def generate_base_test(file, sequence_file)
    file.puts %(

require_relative '../test_helper'      
class #{sequence_file.split(".rb").first}_test < MiniTest::Test
    @fixture = "put fixture file here"
    @sequence_class = "put the name of the sequence class here"

    def setup
        @resource = FHIR::DSTU2.from_contents(load_fixture(@fixture.to_sym))
        @resource_bundle = wrap_resources_in_bundle(@resource)
        @resource_bundle.entry.each do |entry|
            entry.resource.meta = FHIR::DSTU2::Meta.new unless entry.resource.meta
            entry.resource.meta.versionId = '1'
        end
        @resource_bundle.link << FHIR::DSTU2::Bundle::Link.new(url: "http://www.example.com/\#{@resource.resourceType}?patient=pat1")
                            
        @instance = get_test_instance

        @patient_id = @medication_statement.patient.reference
        @patient_id = @patient_id.split('/')[-1] if @patient_id.include?('/')

        @patient_resource = FHIR::DSTU2::Patient.new(id: @patient_id)
        @practitioner_resource = FHIR::DSTU2::Practitioner.new(id: 432)

        # Assume we already have a patient
        @instance.resource_references << Inferno::Models::ResourceReference.new(
        resource_type: 'Patient',
        resource_id: @patient_id
        )

        # Register that the server supports MedicationStatement
        @instance.supported_resources << Inferno::Models::SupportedResource.create(
            resource_type: 'MedicationStatement',
            testing_instance_id: @instance.id,
            supported: true,
            read_supported: true,
            vread_supported: true,
            search_supported: true,
            history_supported: true
        )

        @instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.

        client = get_client(@instance)

        @sequence = Inferno::Sequence::ArgonautMedicationStatementSequence.new(@instance, client)

        @request_headers = { 'Accept' => 'application/json+fhir',
                            'Accept-Charset' => 'utf-8',
                            'User-Agent' => 'Ruby FHIR Client',
                            'Authorization' => "Bearer \#{@instance.token}" }
        @response_headers = { 'content-type' => 'application/json+fhir' }
    end
end
        
        )
end

# assumes sequences are only one layer deep
Dir.entries(sequence_dir).each do |file|
    if File.directory?("#{sequence_dir}/#{file}") && file != '.' && file != '..'
        Dir.mkdir("#{tests_dir}/#{file}") unless File.exists?("#{tests_dir}/#{file}")
        Dir.entries("#{sequence_dir}/#{file}").each do |sequence_file|
            if sequence_file.end_with?(".rb") && !File.exists?("#{tests_dir}/#{file}/#{sequence_file}_test.rb") then
                File.open("#{tests_dir}/#{file}/#{sequence_file.split(".rb").first}_test.rb", "w") do |f|
                    generate_base_test(f, sequence_file)
                end
            end
        end
    end
end
