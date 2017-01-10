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
        client.default_json
        client.get_oauth2_metadata_from_conformance
      end
    end
  end
end
