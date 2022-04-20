module MaxPage
  class MetricsController < ApplicationController
    layout 'max_page/application'

    before_action :before_index

    def index
      @title = MaxPage.config.title
      @metrics = MaxPage.config.metrics
      @metrics.each &:run
      @alright = @metrics.map(&:ok?).all? true
      if @alright
        @message = MaxPage.config.success_message
      else
        @message = MaxPage.config.warning_message
      end
      @metrics_without_group = @metrics.reject(&:group)
      @groups = MaxPage.config.groups
    end

    protected

    def before_index
      block = MaxPage.config.before_action
      if block
        instance_eval(&block)
      end
    end
  end
end
