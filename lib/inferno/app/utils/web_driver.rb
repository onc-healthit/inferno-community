# frozen_string_literal: true

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

      # options.add_argument('--remote-debugging-port=9222')

      # Selenium::WebDriver.logger.output = 'selenium.log'

      script = JSON.parse(json_script)

      driver = Selenium::WebDriver.for :chrome, options: options
      sleep 2
      driver.navigate.to start_url unless start_url.nil?

      wait = Selenium::WebDriver::Wait.new(timeout: 30)

      script.each do |command|
        unless command['find_value'].nil?
          if command['index'].nil?
            wait.until { !driver.find_element(command['type'].to_sym => command['find_value']).nil? }
            current_element = driver.find_element(command['type'].to_sym => command['find_value'])
          else
            wait.until { driver.find_elements(command['type'].to_sym => command['find_value']).any? }
            current_element = driver.find_elements(command['type'].to_sym => command['find_value'])
          end
        end

        case command['cmd']
        when 'send_keys'
          current_element.send_keys(command['value'])
        when 'debugger'
          #binding.pry # rubocop:disable Lint/Debugger
        when 'wait'
          sleep command['value']
        when 'navigate'
          driver.navigate.to command['value']
        when 'click'
          if command['index'].nil?
            driver.action.move_to current_element
            current_element.click
          else
            driver.action.move_to current_element[command['index']]
            current_element[command['index']].click
          end
        end
      end

      sleep 5
      driver.switch_to.window(driver.window_handles.last)

      Rack::Utils.parse_query URI.parse(driver.current_url).query
    end
  end
end
