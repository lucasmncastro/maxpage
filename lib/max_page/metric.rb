module MaxPage
  class Metric
    attr_accessor :name, :description, :verify, :block
    attr_reader :value

    def run
      @value = block.call
    end

    def verify?
      !!verify
    end

    def verify=(rules)
      if rules.is_a? Hash
        invalid_options = rules.keys - [:min, :max]
        raise "Invalid rule: #{invalid_options.join(', ')}" if invalid_options.any?
      end

      @verify = rules
    end

    def ok?
      return true if not verify?

      run if not value

      if verify.is_a? Hash
        validations = verify.map do |rule_name, rule_value|
          case rule_name
          when :min then value.to_i >= rule_value
          when :max then value.to_i <= rule_value
          else
            raise "Invalid rule: #{rule_name}"
          end
        end
        validations.all? true
      else
        value == verify
      end
    end
  end
end
