require "survey_engine/version"
require "survey_engine/engine"
require "survey_engine/configuration"

module SurveyEngine
  class << self
    attr_accessor :configuration
  end
  
  def self.configuration
    @configuration ||= Configuration.new
  end
  
  def self.configure
    yield(configuration)
  end
  
  def self.config
    configuration
  end
end
