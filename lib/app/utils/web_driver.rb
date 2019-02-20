require 'selenium-webdriver'

module Inferno
  module WebDriver
    def run_script(json_script, start_url = nil)
      Selenium::WebDriver.logger.level = :debug

      ENV['NO_PROXY'] = ENV['no_proxy'] = '127.0.0.1'
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument('--headless')
      options.add_argument('--kiosk')
      options.add_argument('--disable-gpu')
      options.add_argument('--incognito')
      options.add_argument('--no-sandbox')


      # options.add_argument('--remote-debugging-port=9222')

      # Selenium::WebDriver.logger.output = 'selenium.log'

      script = JSON.parse(json_script)

      driver = Selenium::WebDriver.for :chrome, options: options
      sleep 2
      driver.navigate.to start_url unless start_url.nil?

      wait = Selenium::WebDriver::Wait.new(:timeout => 30)


      script.each do |command|
        current_element = wait.until {
          if(!command['index'].nil?)
            current = driver.find_elements({command['type'].to_sym => command['find_value']})
          else
            current = driver.find_element({command['type'].to_sym => command['find_value']})
          end

          current if (current.is_a?(Array) && current.length >= (command['index'] || 0) && current[command['index']].displayed?) || (!current.is_a?(Array) && current.displayed?)
        } unless command['find_value'].nil?

        sleep 1

        case command['cmd']
        when 'send_keys'
          current_element.send_keys(command['value'])
        when 'debugger'
          binding.pry
        when 'wait'
          sleep command['value']
        when 'navigate'
          driver.navigate.to command['value']
        when 'click'
          if command['index'] != nil
            driver.action.move_to current_element[command['index']]
            current_element[command['index']].click
          else
            driver.action.move_to current_element
            current_element.click
          end
        end
      end

      sleep 5
      driver.switch_to.window(driver.window_handles.last)

      Rack::Utils.parse_query URI::parse(driver.current_url).query
    end
  end
end

