
module Inferno
  module Sequence
    class BDTBase < SequenceBase

      BDT_URL = 'http://bdt_adapter:4500/execute/'

      def run_bdt(path)
        url = "#{BDT_URL}#{path}"
        begin
          response = RestClient.post(url, nil)
          response.body.split("\n").each do |chunk|
            message = JSON.parse(chunk.strip)

            data = message['data']
            next if data.nil?

            warning {
              data['warnings'].each do |warning|
                assert false, warning
              end
            }
            skip 'Not supported' if data['status'] == 'not-supported'
            assert message['status'] != 'error', data['error']
          end
        rescue => e
          assert false, e.message
        end
      end

    end
  end
end
