module Maxdog
  class MetricsController < ApplicationController
    def index
      @title = Maxdog.config.title
      @metrics = Maxdog.config.metrics
      @metrics.each &:run
      @alright = @metrics.map(&:ok?).all? true
    end
  end
end
