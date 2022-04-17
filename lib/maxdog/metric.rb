module Maxdog
  class Metric
    attr_accessor :name, :description, :block

    def value
      block.call
    end
  end
end
