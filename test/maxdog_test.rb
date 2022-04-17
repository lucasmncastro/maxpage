require "test_helper"

class MaxdogTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert Maxdog::VERSION
  end

  test "title setting" do
    Maxdog.setup do
      title 'Status page'
    end

    assert_equal 'Status page', Maxdog.config.title
  end

  test "simple metric" do
    Maxdog.setup do
      metric "Today's sales" do
        10
      end
    end

    metric = Maxdog.config.metrics.first
    assert_equal "Today's sales", metric.name
    assert_equal 10, metric.value
  end

  test "multiple metrics" do
    Maxdog.setup do
      metric("M1") { 1 }
      metric("M2") { 2 }
      metric("M3") { 3 }
    end

    assert_equal %w(M1 M2 M3), Maxdog.config.metrics.map(&:name)
    assert_equal [1, 2, 3], Maxdog.config.metrics.map(&:value)
  end

  test "metric with description" do
    Maxdog.setup do
      metric 'New users', description: 'number of users who registered today' do
        13
      end
    end

    metric = Maxdog.config.metrics.first
    assert_equal 'number of users who registered today', metric.description
  end
end
