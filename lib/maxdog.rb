require "maxdog/version"
require "maxdog/engine"
require "maxdog/configuration"
require "maxdog/metric"

module Maxdog
  class << self
    def setup(&block)
      @config = Configuration.new
      config.instance_eval &block
    end

    def config
      @config
    end
  end
end
