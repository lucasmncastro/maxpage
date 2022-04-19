require "test_helper"

class MaxPageTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert MaxPage::VERSION
  end

  test "title setting" do
    MaxPage.setup do
      title 'Status page'
    end

    assert_equal 'Status page', MaxPage.config.title
  end

  test "success message" do
    MaxPage.setup do
      success_message 'Tudo certo'
    end
    assert_equal 'Tudo certo', MaxPage.config.success_message
  end

  test "warning message" do
    MaxPage.setup do
      warning_message 'Deu ruim'
    end
    assert_equal 'Deu ruim', MaxPage.config.warning_message
  end

  test "simple metric" do
    MaxPage.setup do
      metric "Today's sales" do
        10
      end
    end

    metric = MaxPage.config.metrics.first
    assert_equal "Today's sales", metric.name
    assert_equal 10, metric.run
  end

  test "multiple metrics" do
    MaxPage.setup do
      metric("M1") { 1 }
      metric("M2") { 2 }
      metric("M3") { 3 }
    end

    assert_equal %w(M1 M2 M3), MaxPage.config.metrics.map(&:name)
    assert_equal [1, 2, 3], MaxPage.config.metrics.map(&:run)
  end

  test "metric with description" do
    MaxPage.setup do
      metric 'New users', description: 'number of users who registered today' do
        13
      end
    end

    metric = MaxPage.config.metrics.first
    assert_equal 'number of users who registered today', metric.description
  end

  test "verify min value" do
    MaxPage.setup do
      metric 'New users last 24h', verify: { min: 10 } do
        9
      end

      metric 'Publications last 24h', verify: { min: 50 } do
        51
      end
    end

    users, publications = MaxPage.config.metrics

    assert !users.ok?
    assert publications.ok?
  end

  test "verify max value" do
    MaxPage.setup do
      metric 'Delayed job failures', verify: { max: 0 } do
        1
      end

      metric 'Unpublications', verify: { max: 10 } do
        3
      end
    end

    failures, unpublications = MaxPage.config.metrics

    assert !failures.ok?
    assert unpublications.ok?
  end

  test "verify range value with max and min" do
    MaxPage.setup do
      metric 'Pods running in namespace A', verify: { min: 5, max: 10 } do
        6
      end

      metric 'Pods running in namespace B', verify: { min: 5, max: 10 } do
        20
      end
    end

    pods_a, pods_b = MaxPage.config.metrics
    assert pods_a.ok?
    assert !pods_b.ok?
  end

  test "verify exact values" do
    MaxPage.setup do
      metric 'Backend health check', verify: true do
        true
      end

      metric 'Number of running pods', verify: 10 do
        11
      end
    end

    health, pods = MaxPage.config.metrics

    assert health.ok?
    assert !pods.ok?
  end

  test "validate verify option on setup" do
    assert_raise RuntimeError do
      MaxPage.setup do
        metric 'Backend health check', verify: { invalid_rule: true } do
          1
        end
      end
    end
  end

  test "before_action option" do
    MaxPage.setup do
      before_action do
        'Ok'
      end
      metric('Backend health check') { true }
    end

    assert_equal 'Ok', MaxPage.config.before_action.call
  end
end
