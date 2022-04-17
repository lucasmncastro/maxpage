module Maxdog
  class Configuration
    attr_reader :metrics

    def initialize
      @metrics = []
    end

    # Same method to set and get the title.
    def title(title=nil)
      return @title if title.nil?

      @title = title
    end

    # Add a metric.
    def metric(name, description: nil, verify: nil, &block)
      metric = Metric.new
      metric.name = name
      metric.description = description
      metric.verify = verify
      metric.block = block

      @metrics << metric
    end
  end
end
