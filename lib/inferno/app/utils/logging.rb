# frozen_string_literal: true

module Inferno
  # Returns the Inferno Logger
  #
  # @return the logger object
  def self.logger
    @logger || default_logger
  end

  # Allows setting the logger object
  #
  # A virtual attribute assignment method
  #
  # @return the logger object
  def self.logger=(logger)
    @logger = logger
  end

  # Creates a defualt logger which outputs to STDOUT
  #
  # @return the default logger
  def self.default_logger
    @default_logger ||= Inferno::Logger.new(STDOUT)
  end
end
