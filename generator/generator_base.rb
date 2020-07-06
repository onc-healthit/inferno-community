# frozen_string_literal: true

require 'erb'
require 'pry'
require 'fileutils'
require 'net/http'
require 'fhir_models'

module Inferno
  module Generator
    class Base
      attr_accessor :path, :extras, :resource_by_path, :resources_by_type,
                    :claimed_test_id_prefixes

      def initialize(path, extras)
        @path = path
        @extras = extras
        @claimed_test_id_prefixes = Set.new
        load_resources
      end

      def load_resources
        @resource_by_path = Hash.new {}
        @resources_by_type = Hash.new { |h, k| h[k] = [] }
        Dir.glob("#{resource_file_path}/**/*.*") do |resource| # note one extra "*"
          if File.file?(resource) && resource.end_with?('json', 'xml')

            # We should consider using the native Ruby models instead of JSON
            # There were problems with round-tripping certain SearchParameters though
            new_resource_json = JSON.parse(File.read(resource))
            new_resource = FHIR.from_contents(File.read(resource))
            if new_resource.id == 'searchParams'
              new_resource.entry.each_with_index do |entry, index|
                type = 'SearchParameter'
                search_parameter_resource = entry.resource
                next if resource_path(search_parameter_resource) == 'SearchParameter/SearchParameter-code'

                search_parameter_json = new_resource_json['entry'][index]['resource']
                resource_by_path[resource_path(search_parameter_resource)] = search_parameter_json
                resources_by_type[type].push(search_parameter_json)
              end
            else
              resource_by_path[resource_path(new_resource)] = new_resource_json
              type = new_resource.class.name.demodulize
              type = 'CapabilityStatement' if type == 'Conformance'
              resources_by_type[type].push(new_resource_json)
            end
          end
        end
      end

      def ig_resource
        resources_by_type['ImplementationGuide'].first
      end

      def capability_statement(mode = 'server')
        resources_by_type['CapabilityStatement'].find do |capability_statement_resource|
          capability_statement_resource['rest'].any? { |r| r['mode'] == mode }
        end
      end

      def capability_statement_by_id(id)
        resources_by_type['CapabilityStatement'].find do |capability_statement_resource|
          capability_statement_resource['id'] == id
        end
      end

      def resource_path(resource)
        "#{resource.class.name.demodulize}/#{resource.id}"
      end

      def format_output
        system("rubocop -x --display-only-fail-level-offenses #{sequence_out_path}")
      end

      def run
        generate
        format_output
      end

      # subclass must implement the following
      def generate
        raise StandardError('Method not implemented.')
      end

      def sequence_prefix
        version = ig_resource['version'].delete('.')
        name = ig_metadata['name']
        "#{version}#{name}"
      end

      def module_yml_out_path
        File.expand_path('./lib/modules/')
      end

      def sequence_out_path
        File.expand_path("#{module_yml_out_path}/#{path}")
      end

      def resource_file_path
        File.expand_path("./resources/#{path}")
      end
    end
  end
end
