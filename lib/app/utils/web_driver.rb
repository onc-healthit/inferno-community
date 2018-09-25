require 'selenium-webdriver'

module Inferno
  module WebDriver
    def run_standalone_launch(url)
      Selenium::WebDriver.logger.level = :debug

      ENV['NO_PROXY'] = ENV['no_proxy'] = '127.0.0.1'
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument('--headless')
      options.add_argument('--disable-gpu')
      options.add_argument('--incognito')

      # options.add_argument('--remote-debugging-port=9222')

      # Selenium::WebDriver.logger.output = 'selenium.log'

      script = JSON.parse(@instance.standalone_launch_script)

      driver = Selenium::WebDriver.for :chrome, options: options
      sleep 2
      driver.navigate.to url

      wait = Selenium::WebDriver::Wait.new(:timeout => 15)


      script.each do |command|
        current_element = wait.until {
          if(command['index'])
            current = driver.find_elements({command['type'].to_sym => command['find_value']})
          else
            current = driver.find_element({command['type'].to_sym => command['find_value']})
          end

          current if (current.is_a?(Array) && current.length>0) || (!current.is_a?(Array) && current.displayed?)
        }

        case command['cmd']
        when 'send_keys'
          current_element.send_keys(command['value'])
        when 'click'
          if command['index'] != nil
            current_element[command['index']].click
          else
            current_element.click
          end
        end
      end

      Rack::Utils.parse_query URI::parse(driver.current_url).query
    end
  end
end

