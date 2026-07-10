require "test_helper"

module MaxPage
  class StatusMailerTest < ActionMailer::TestCase
    test "formats decimal metric values and verify thresholds with limited precision" do
      MaxPage.setup do
        metric "Compra de serviços de IA", verify: { min: 4.8999999999999995 } do
          4
        end
      end

      email = StatusMailer.status_report

      assert_match "Current value: 4", email.body.to_s
      assert_match "Minimum required: 4.9", email.body.to_s
      assert_no_match(/4\.8999999999999995/, email.body.to_s)
    end

    test "renders integer metric values without decimals" do
      MaxPage.setup do
        metric "Compras com status failed", verify: { max: 0 } do
          4
        end
      end

      email = StatusMailer.status_report

      assert_match "Current value: 4", email.body.to_s
      assert_match "Maximum allowed: 0", email.body.to_s
    end
  end
end
