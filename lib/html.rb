module Crucible
  module App
    class Html

      attr_accessor :body
      attr_accessor :alt
      attr_accessor :pass
      attr_accessor :not_found
      attr_accessor :fail
      attr_accessor :skip

      def initialize
        @pass = 0
        @not_found = 0
        @fail = 0
        @skip = 0
      end

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
              span {
                font-family: monospace;
                font-weight: bold;
              }
              span.pass {
                color: #008000;
              }
              span.not_found {
                background-color: #FFFF00;
              }
              span.skip {
                color: #0000FF;
              }
              span.fail {
                color: #B22222;
              }
              .header img {
                float: left;
                width: 50px;
                height: 50px;
              }
              .header h1 {
                position: relative;
                top: 10px;
                left: 10px;
              }
            </style>
            <script src="https://code.jquery.com/jquery-1.12.4.js"></script>
            <script src="jquery-ui-1.12.1.custom/jquery-ui.js"></script>
            <script>
              $( function() {
                $( "#accordion" ).accordion({
                  collapsible: true,
                  heightStyle: "content",
                  active: -1
                });
              } );
            </script>
          </head>
          <body>
          <div class="header">
            <img src="images/logo.png" alt="Crucible" />
            <h1>Crucible SMART-on-FHIR App (DSTU2)</h1>
          </div>
          <div id="accordion">'
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

      # Make an assertion
      def assert(description,success,detail='Not available')
        detail = 'Not available' if detail.nil?
        if success==:not_found
          @not_found += 1
          status = '<span class="not_found">NOT FOUND</span>'
        elsif success==:skip
          @skip += 1
          status = '<span class="skip">SKIPPED</span>'
        elsif success
          @pass += 1
          status = '<span class="pass">PASS</span>'
        else
          @fail += 1
          status = '<span class="fail">FAIL</span>'
        end
        add_table_row([ status, description, detail ])
      end

      # Assert the search found items
      def assert_search_results(name,reply)
        begin
          length = reply.resource.entry.length
          detail = "Found #{length} #{name}."
          if length == 0
            status = :not_found
          elsif length > 0
            status = true
          else
            status = false
            detail = "HTTP Status #{reply.code}&nbsp;#{reply.body}"
          end
        rescue
          status = false
          detail = "HTTP Status #{reply.code}&nbsp;#{reply.body}"
        end
        assert(name,status,detail)
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

      # Add an HTML Form
      def add_form(name,action,fields=Hash.new(''))
        @body += '</div><div>'
        @body += "<form method=\"POST\" action=\"#{action}\">"
        start_table(name)
        fields.each do |key, value|
          field = "<input type=\"text\" size=\"50\" name=\"#{key}\" value=\"#{value}\" required>"
          add_table_row([key,field])
        end
        end_table
        @body += "<input type=\"submit\"></form>"
        self
      end

    end
  end
end
