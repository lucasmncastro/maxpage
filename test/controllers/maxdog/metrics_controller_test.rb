require "test_helper"

module Maxdog
  class MetricsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    def setup
      Maxdog.setup do
        metric "Health check", verify: true do
          true
        end
      end
    end

    test "should set page title" do
      Maxdog.setup do
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
      Maxdog.setup do
        metric("Health check", description: 'Verify if server is up', verify: true) { true }
      end
      get metrics_index_url
      assert_select '.text-muted', text: 'Verify if server is up'
    end

    test "should show the check icon if verify has passed" do
      Maxdog.setup do
        metric("Health check", verify: true) { true }
      end
      get metrics_index_url
      assert_select '.list-group-item .bi-check-circle-fill'
    end

    test "should show success message if is all right" do
      Maxdog.setup do
        metric("Check PostgreSQL", verify: true) { true }
        metric("Check MySQL", verify: true) { true }
      end
      get metrics_index_url
      assert_select 'h1', text: "It's all right!"
    end

    test "should show alert message if is something wrong" do
      Maxdog.setup do
        metric("Check PostgreSQL", verify: true) { true }
        metric("Check MySQL", verify: true) { false }
      end
      get metrics_index_url
      assert_select 'h1', text: 'Something is wrong!'
    end
  end
end
