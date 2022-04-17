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
    assert_equal 10, metric.run
  end

  test "multiple metrics" do
    Maxdog.setup do
      metric("M1") { 1 }
      metric("M2") { 2 }
      metric("M3") { 3 }
    end

    assert_equal %w(M1 M2 M3), Maxdog.config.metrics.map(&:name)
    assert_equal [1, 2, 3], Maxdog.config.metrics.map(&:run)
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

  test "verify min value" do
    Maxdog.setup do
      metric 'New users last 24h', verify: { min: 10 } do
        9
      end

      metric 'Publications last 24h', verify: { min: 50 } do
        51
      end
    end

    users, publications = Maxdog.config.metrics

    assert !users.ok?
    assert publications.ok?
  end

  test "verify max value" do
    Maxdog.setup do
      metric 'Delayed job failures', verify: { max: 0 } do
        1
      end

      metric 'Unpublications', verify: { max: 10 } do
        3
      end
    end

    failures, unpublications = Maxdog.config.metrics

    assert !failures.ok?
    assert unpublications.ok?
  end

  test "verify range value with max and min" do
    Maxdog.setup do
      metric 'Pods running in namespace A', verify: { min: 5, max: 10 } do
        6
      end

      metric 'Pods running in namespace B', verify: { min: 5, max: 10 } do
        20
      end
    end

    pods_a, pods_b = Maxdog.config.metrics
    assert pods_a.ok?
    assert !pods_b.ok?
  end

  test "verify exact values" do
    Maxdog.setup do
      metric 'Backend health check', verify: true do
        true
      end

      metric 'Number of running pods', verify: 10 do
        11
      end
    end

    health, pods = Maxdog.config.metrics

    assert health.ok?
    assert !pods.ok?
  end

  test "validate verify option on setup" do
    assert_raise RuntimeError do
      Maxdog.setup do
        metric 'Backend health check', verify: { invalid_rule: true } do
          1
        end
      end
    end
  end
end
