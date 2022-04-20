module MaxPage
  class Configuration
    attr_reader :metrics, :groups

    def initialize
      @groups = []
      @metrics = []
      @success_message = "It's all right!"
      @warning_message = "Something is wrong!"
    end

    # Same method to set and get the title.
    def title(title=nil)
      return @title if title.nil?

      @title = title
    end

    # Same method to set and get the before_action block.
    def before_action(&block)
      return @before_action if block.nil?

      @before_action ||= block
    end

    # Same method to set and get the title.
    def success_message(message=nil)
      return @success_message if message.nil?

      @success_message = message
    end

    # Same method to set and get the title.
    def warning_message(message=nil)
      return @warning_message if message.nil?

      @warning_message = message
    end

    # Add a metric.
    def metric(name, description: nil, verify: nil, &block)
      metric = Metric.new
      metric.name = name
      metric.description = description
      metric.verify = verify
      metric.block = block

      if @current_group
        metric.group = @current_group
        @current_group.metrics << metric
      end

      @metrics << metric
    end

    def group(name=nil, &block)
      group = Group.new
      group.name = name
      group.metrics = []

      @current_group = group
      instance_eval(&block)
      @current_group = nil

      @groups << group
    end
  end
end
