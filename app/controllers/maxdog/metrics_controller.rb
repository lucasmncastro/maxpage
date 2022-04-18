module Maxdog
  class MetricsController < ApplicationController
    layout 'maxdog/application'

    before_action :before_index

    def index
      @title = Maxdog.config.title
      @metrics = Maxdog.config.metrics
      @metrics.each &:run
      @alright = @metrics.map(&:ok?).all? true
    end

    protected

    def before_index
      block = Maxdog.config.before_action
      if block
        instance_eval(&block)
      end
    end
  end
end
