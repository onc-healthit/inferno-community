module Crucible
  module App
    class Html

      attr_accessor :body

      def open
        @body = '<html>
          <head>
            <title>Crucible SMART-on-FHIR DSTU2 App</title>
            <link rel="stylesheet" href="jquery-ui-1.12.1.custom/jquery-ui.css">
            <link rel="stylesheet" href="http://yui.yahooapis.com/pure/0.6.0/pure-min.css">
            <style>
              table {
                  border-collapse: collapse;
              }
              table, td, th {
                  border: 1px solid black;
              }
            </style>
            <script src="https://code.jquery.com/jquery-1.12.4.js"></script>
            <script src="jquery-ui-1.12.1.custom/jquery-ui.js"></script>
            <script>
              $( function() {
                $( "#accordion" ).accordion({
                  collapsible: true,
                  heightStyle: "content",
                  active: 3
                });
              } );
            </script>
          </head>
          <body><h1>Crucible SMART-on-FHIR DSTU2 App</h1><div id="accordion">'
        self
      end

      def close
        @body += '</div></body></html>'
      end

      # Output a Hash as an HTML Table
      def echo_hash(name,hash,headers=[])
        content = "<h3>#{name}</h3><table class=\"pure-table\">"
        if !headers.empty?
          content += "<thead><tr>"
          headers.each do |title|
            content += "<th>#{title}</th>"
          end
          content += "</tr></thead>"
        end
        content += "<tbody>"
        alt = true
        hash.each do |key,value|
          if alt
            content += "<tr class=\"pure-table-odd\"><td>#{key}</td>"
          else
            content += "<tr><td>#{key}</td>"
          end
          alt = !alt
          if value.is_a?(Hash)
            value.each do |sk,sv|
              content += "<td>#{sv}</td>"
            end
            content += "</tr>"
          else
            content += "<td>#{value}</td></tr>"
          end
        end
        content += '</tbody></table>'
        @body += content
        self
      end
    end
  end
end
