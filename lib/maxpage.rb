require "max_page/version"
require "max_page/engine"
require "max_page/configuration"
require "max_page/metric"
require "max_page/group"

module MaxPage
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
