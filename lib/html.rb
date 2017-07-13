module Crucible
  module App
    class Html

      attr_accessor :stream
      attr_accessor :body
      attr_accessor :alt
      attr_accessor :pass
      attr_accessor :not_found
      attr_accessor :fail
      attr_accessor :skip

      def initialize(stream=nil)
        @stream = stream
        @body = ''
        @pass = 0
        @not_found = 0
        @fail = 0
        @skip = 0
      end

      # For a streaming IO
      def output(string)
        if @stream
          @stream << string
        else
          @body += string
        end
      end

      def open
        @body = ''
        output "<html>
          <head>
            <title>Crucible SMART-on-FHIR DSTU2 App</title>
            <link rel=\"stylesheet\" href=\"#{base_url}/css/pure-min.css\">
            <link rel=\"stylesheet\" href=\"#{base_url}/css/font.css\">
            <script src=\"//code.jquery.com/jquery-1.12.4.js\"></script>
            <script src=\"#{base_url}/jquery-ui-1.12.1.custom/jquery-ui.js\"></script>
            <script>
              $( function() {
                $( \"#accordion\" ).accordion({
                  collapsible: true,
                  heightStyle: \"content\",
                  active: -1
                });
              } );
            </script>
            <style>
              html {
                color: #333333;
              }
              .title {
                padding-left: 15px;
                padding-right: 15px;
              }
              .main {
                width: 970px;
                margin-top: 30px;
                margin-left: auto;
                margin-right: auto;
              }
              h3 {
                background-color: #FFF;
                color: #4A6E98;
                display: block;
                font-size: 18px;
                border: 1px solid #4A6E98;
                border-radius: 5px;
                padding: 10px;
                padding-bottom: 7px;
              }
              table.data {
                table-layout: fixed;
                border-width: 2px;
                border-style: solid;
                border-color: rgb(221,221,221);
                color: #333333;
                border-collapse: collapse;
                font-size: 18px;
              }
              th {
                font-weight: bold;
              }
              tr {
                background-color: #FFF;
                color: #000;
              }
              td.last {
                word-break: break-all;
              }
              p, ul, ol {
                font-size: 14px;
              }
              span.pass {
                color: #008000;
              }
              span.not_found {
                color: #FF4500;
              }
              span.skip {
                color: #0000FF;
              }
              span.fail {
                color: #B22222;
              }
              input {
                margin-top: 10px;
                margin-bottom: 10px;
              }
              input[type=button], input[type=submit], input[type=reset] {
                background-color: #B74C18;
                color: #FFF;
                border: 1px solid #B74C18;
                border-radius: 5px;
                padding: 10px;
                padding-bottom: 7px;
              }
              input[type=button]:hover, input[type=submit]:hover, input[type=reset]:hover {
                background-color: #FFF;
                color: #B74C18;
                border: 1px solid #B74C18;
                border-radius: 5px;
                padding: 10px;
                padding-bottom: 7px;
              }
              #accordion .ui-accordion-header {
                background-color: #FFF;
                color: #4A6E98;
                display: block;
                font-size: 18px;
                border: 1px solid #4A6E98;
                border-radius: 5px;
                padding-top: 10px;
                padding-bottom: 7px;
              }
              #accordion .ui-accordion-header:hover {
                background-color: #4A6E98;
                color: #FFF;
                display: block;
                font-size: 18px;
                border: 1px solid #4A6E98;
                border-radius: 5px;
                padding-top: 10px;
                padding-bottom: 7px;
              }
              #accordion .ui-accordion-content {
                background-color: #FFF;
                color: #000;
                font-size: 18px;
              }
            </style>
            <script>
              var scrollToBottom = function() {
                window.scrollTo(0, document.body.scrollHeight);
              }
              var intervalID = setInterval(scrollToBottom, 200);
            </script>
          </head>
          <body>
            <header>
              <div class=\"container\">
                <div class=\"navbar-header\">
                  <button class=\"navbar-toggle collapsed\" type=\"button\" data-toggle=\"collapse\" data-target=\".bs-navbar-collapse\">
                    <span class=\"sr-only\">Toggle navigation</span>
                    <span class=\"icon-bar\"></span>
                    <span class=\"icon-bar\"></span>
                    <span class=\"icon-bar\"></span>
                  </button>
                  <a href=\"https://projectcrucible.org\" class=\"navbar-brand\">CRUCIBLE</a>
                </div>
                <nav class=\"collapse navbar-collapse\">
                  <ul class=\"nav navbar-nav pull-right\">
                    <li><a href=\"https://projectcrucible.org\" class=\"navButton\">Server Test</a></li>
                    <li><a href=\"https://projectcrucible.org/scorecard\" class=\"navButton\">Scorecard</a></li>
                    <li><a href=\"https://projectcrucible.org/testdata\" class=\"navButton\">Test Data</a></li>
                    <li><a href=\"/\" class=\"navButton\">SMART on FHIR</a></li>
                    <li><a href=\"https://beta.projectcrucible.org\" class=\"navButton\">DSTU2 Version</a></li>
                    <li class=\"dropdown\">
                      <a href=\"#\" class=\"navButton\" data-toggle=\"dropdown\" id=\"contact-drop\" role=\"button\" aria-haspopup=\"true\" aria-expanded=\"false\">Contact Us<span class=\"caret\"></span></a>
                      <ul class=\"dropdown-menu\" aria-labelledby=\"contact-drop\">
                        <li><a class=\"navButton\" href=\"mailto:fhir-testing-list@lists.mitre.org?subject=Crucible\">Email Us</a></li>
                        <li><a class=\"navButton\" target=\"_blank\" href=\"https://chat.fhir.org/#narrow/stream/crucible\">FHIR Chat</a></li>
                        <li><a class=\"navButton\" target=\"_blank\" href=\"https://github.com/fhir-crucible/crucible/issues\">Log an issue</a></li>
                      </ul>
                    </li>
                  </ul>
                </nav>
              </div>
            </header>
            <div class=\"main\">
              <div class=\"title\">
                <h1>SMART on <span style=\"color: #B74C18\">FHIR</span></h1>
                <div class=\"well helper_text\">
                  Crucible SMART App is a <a href=\"http://smarthealthit.org/smart-on-fhir/\" target=\"_blank\">SMART-on-FHIR App</a> that executes a series of tests against an HL7® FHIR® Server.
                  <br>
                  <br>
                  These tests focus on <a href=\"http://hl7.org/fhir/DSTU2/index.html\" target=\"_blank\">FHIR DSTU2</a> and in particular the <a href=\"http://hl7.org/fhir/DSTU2/daf/daf.html\" target=\"_blank\">DAF Implementation Guide</a> and <a href=\"http://hl7.org/fhir/DSTU2/argonaut/argonaut.html\" target=\"_blank\">Argonauts</a> Use-Cases.
                </div>
              </div>
            <div id=\"accordion\">"
        self
      end

      def close
        output '</div>
          </div>
          <script>
            window.clearInterval(intervalID);
            window.scrollTo(0, 0);
          </script>
          </body>
          </html>'
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
      def start_table(name,headers=[],in_accordion=true)
        if in_accordion
          output "<h3>#{name}</h3><table class=\"pure-table pure-table-horizontal data\">"
        else
          output "<h2>#{name}</h2><table class=\"pure-table pure-table-horizontal data\">"
        end
        if !headers.empty?
          output '<thead><tr>'
          headers.each do |title|
            output "<th>#{title}</th>"
          end
          output '</tr></thead>'
        end
        output '<tbody>'
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
        output '<tr>'
        row.each do |col|
          if !col.equal?(row.last)
            output "<td>#{col}</td>"
          else
            output "<td class=\"last\">#{col}</td>"
          end
        end
        output '</tr>'
        self
      end

      # Close an HTML Table
      def end_table
        output '</tbody></table>'
        self
      end

      # Add an HTML Form
      def add_form(name,action,fields=Hash.new(''))
        output '</div><div>'
        output "<form method=\"POST\" action=\"#{base_url}#{action}\">"
        start_table(name,[],false)
        fields.each do |key, value|
          field = "<input type=\"text\" size=\"50\" name=\"#{key}\" value=\"#{value}\" required>"
          add_table_row([key,field])
        end
        end_table
        output "<input type=\"submit\"></form>"
        self
      end

      def base_url
        Crucible::App::Config::CONFIGURATION['base_url']
      end

      def instructions
        output "</div><div>
          <h2>Instructions</h2>
          <h4>Configuring Client ID and Scopes (required)</h4>
          <p>OAuth2 client IDs and scopes for different FHIR servers must be stored in the
          <a href=\"#{base_url}/config\">/config</a> section, so the SMART app can be used with multiple FHIR server
          implementations.</p>

          <p>Each entry under <code>client_id</code> and <code>scopes</code> should be a unique substring within
          the FHIR server URL (for example, <code>cerner</code> or <code>epic</code>), with the value being the
          associated client ID to use or OAuth2 scopes to request.</p>

          <h4>Launching the App</h4>

          <ul>
          <li>Using Cerner Millenium

          <ol>
          <li>Create an account on <a href=\"https://code.cerner.com\">code.cerner.com</a></li>
          <li>Register a \"New App\"

          <ul>
          <li>Launch URI: <code>https://projectcrucible.org/smart/launch</code></li>
          <li>Redirect URI: <code>https://projectcrucible.org/smart/app</code></li>
          <li>App Type: <code>Provider</code></li>
          <li>FHIR Spec: <code>dstu2_patient</code></li>
          <li>Authorized: <code>Yes</code></li>
          <li>Scopes: <em>select all the Patient Scopes</em></li>
          </ul></li>
          <li>Select your App under \"My Apps\"</li>
          <li>Follow the directions and \"Begin Testing\"</li>
          </ol></li>

          <li>Using Epic

          <ol>
          <li>Create an account on <a href=\"https://open.epic.com\">open.epic.com</a>.</li>
          <li>Navigate to the <a href=\"https://open.epic.com/Launchpad/Oauth2Sso\">Launchpad</a>.</li>
          <li>Enter the details:

          <ul>
          <li>Launch URL: <code>https://projectcrucible.org/smart/launch</code></li>
          <li>Redirect URL: <code>https://projectcrucible.org/smart/app</code></li>
          </ul></li>
          <li>Click \"Launch App\"</li>
          </ol></li>
          </ul>

          <p>Errors encountered during launch are probably associated with improper
          configuration of the client ID and scopes.</p>"
        self
      end

    end
  end
end
