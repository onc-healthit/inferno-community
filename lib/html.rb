module Crucible
  module App
    class Html

      attr_accessor :body
      attr_accessor :alt

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
        start_table(name,headers)
        @alt = true
        hash.each do |key,value|
          if value.is_a?(Hash)
            add_table_row(value.values.insert(0,key))
          else
            add_table_row([key, value])
          end
        end
        end_table
        self
      end

      # Start an HTML Table
      def start_table(name,headers=[])
        @body += "<h3>#{name}</h3><table class=\"pure-table\">"
        if !headers.empty?
          @body += '<thead><tr>'
          headers.each do |title|
            @body += "<th>#{title}</th>"
          end
          @body += '</tr></thead>'
        end
        @body += '<tbody>'
        self
      end

      # Add a table row to the open HTML Table
      def add_table_row(row=[])
        if @alt
          @body += "<tr class=\"pure-table-odd\">"
        else
          @body += '<tr>'
        end
        @alt = !@alt
        row.each do |col|
          @body += "<td>#{col}</td>"
        end
        @body += '</tr>'
        self
      end

      # Close an HTML Table
      def end_table
        @body += '</tbody></table>'
        self
      end

    end
  end
end
