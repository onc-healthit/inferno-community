module Crucible
  module App
    class Config

      # Load the client_ids and scopes from a configuration file
      CONFIGURATION = YAML.load(File.open(File.join(File.dirname(File.absolute_path(__FILE__)),'..','config.yml'),'r:UTF-8',&:read))

      # Given a URL, choose a client_id to use
      def self.get_client_id(url)
        return nil unless url
        CONFIGURATION['client_id'].each do |key,value|
          return value if url.include?(key)
        end
        nil
      end

      # Given a URL, choose the OAuth2 scopes to request
      def self.get_scopes(url)
        return nil unless url
        CONFIGURATION['scopes'].each do |key,value|
          return value if url.include?(key)
        end
        nil
      end

      # Extract the Authorization and Token URLs
      # from the FHIR Conformance
      def self.get_auth_info(issuer)
        return {} unless issuer
        client = FHIR::Client.new(issuer)
        client.default_format = FHIR::Formats::ResourceFormat::RESOURCE_JSON
        client.default_format_bundle = FHIR::Formats::FeedFormat::FEED_JSON
        client.get_oauth2_metadata_from_conformance
      end

      def self.get_config
        rows = []
        CONFIGURATION['client_id'].each do |client,client_id|
          scopes = CONFIGURATION['scopes'][client]
          rows << [ client, client_id, scopes ]
        end
        rows
      end

      # Add a client ID and scopes to the CONFIGURATION
      def self.add_client(name,client_id,scopes)
        CONFIGURATION['client_id'][name] = client_id
        CONFIGURATION['scopes'][name] = scopes
        save
      end

      # Delete a client ID and scopes from the CONFIGURATION
      def self.delete_client(name)
        CONFIGURATION['client_id'].delete(name)
        CONFIGURATION['scopes'].delete(name)
        save
      end

      # Save the current state of the CONFIGURATION to the config.yml file.
      def self.save
        File.open(File.join(File.dirname(File.absolute_path(__FILE__)),'..','config.yml'),'w:UTF-8') do |file|
          file.write CONFIGURATION.to_yaml
        end
      end

    end
  end
end
