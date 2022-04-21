require "test_helper"

module MaxPage
  class MetricsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    def setup
      MaxPage.setup do
        metric "Health check", verify: true do
          true
        end
      end
    end

    test "should set page title" do
      MaxPage.setup do
        title "My page status"
      end
      get metrics_index_url
      assert_select 'title', 'My page status'
    end

    test "should get index" do
      get metrics_index_url
      assert_response :success
    end

    test "should show the metrics" do
      get metrics_index_url
      assert_select '.list-group-item', text: "Health check" 
    end

    test "should show the metrics description" do
      MaxPage.setup do
        metric("Health check", description: 'Verify if server is up', verify: true) { true }
      end
      get metrics_index_url
      assert_select '.text-muted', text: 'Verify if server is up'
    end

    test "should show the check icon if verify has passed" do
      MaxPage.setup do
        metric("Health check", verify: true) { true }
      end
      get metrics_index_url
      assert_select '.list-group-item .bi-check-circle-fill'
    end

    test "should show success message if is all right" do
      MaxPage.setup do
        metric("Check PostgreSQL", verify: true) { true }
        metric("Check MySQL", verify: true) { true }
      end
      get metrics_index_url
      assert_select 'h1', text: "It's all right!"
    end

    test "should show the custom success message" do
      MaxPage.setup do
        success_message 'Tudo certo!'
        metric("Check PostgreSQL", verify: true) { true }
        metric("Check MySQL", verify: true) { true }
      end
      get metrics_index_url
      assert_select 'h1', text: "Tudo certo!"
    end

    test "should show alert message if is something wrong" do
      MaxPage.setup do
        metric("Check PostgreSQL", verify: true) { true }
        metric("Check MySQL", verify: true) { false }
      end
      get metrics_index_url
      assert_select 'h1', text: 'Something is wrong!'
    end

    test "should show the custom warning message" do
      MaxPage.setup do
        warning_message 'Alerta!'
        metric("Check PostgreSQL", verify: true) { true }
        metric("Check MySQL", verify: true) { false }
      end
      get metrics_index_url
      assert_select 'h1', text: "Alerta!"
    end

    test "should run before action callback" do
      MaxPage.setup do
        before_action do
          redirect_to root_path
        end

        metric("Check PostgreSQL", verify: true) { true }
      end
      get metrics_index_url
      assert_redirected_to root_path
    end

    test "should render grouped and not grouped metrics" do
      MaxPage.setup do
        metric("Test 1", verify: true) { true }
        metric("Test 2", verify: true) { true }

        group "group A" do
          metric("Test 3", verify: true) { true }
          metric("Test 4", verify: true) { true }
        end

        group "group B" do
          metric("Test 5", verify: true) { true }
          metric("Test 6", verify: true) { true }
        end
      end

      get metrics_index_url
      assert_select '.list-group-item', text: "Test 1", count: 1
      assert_select '.list-group-item', text: "Test 2", count: 1
      assert_select '.list-group-item', text: "Test 3", count: 1
      assert_select '.list-group-item', text: "Test 4", count: 1
      assert_select '.list-group-item', text: "Test 5", count: 1
      assert_select '.list-group-item', text: "Test 6", count: 1
    end

    test "should not render list-group when there is no grouped metrics" do
      MaxPage.setup do
        group "group A" do
          metric("Test 3", verify: true) { true }
          metric("Test 4", verify: true) { true }
        end

        group "group B" do
          metric("Test 5", verify: true) { true }
          metric("Test 6", verify: true) { true }
        end
      end

      get metrics_index_url
      assert_select '.list-group', count: 2
    end
  end
end
