module MaxPage
  module MetricsHelper
    def format_metric_value(value)
      return value unless value.is_a?(Numeric)
      return value if value.is_a?(Integer)

      number_with_precision(value, precision: 2, strip_insignificant_zeros: true)
    end
  end
end
