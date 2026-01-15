namespace :maxpage do
  desc "Check all metrics and send status report email"
  task check: :environment do
    config = MaxPage.config
    
    # Check if email is configured
    unless config.email_to
      puts "ERROR: Email recipient not configured. Set email_to in MaxPage.setup or MAXPAGE_EMAIL_TO environment variable."
      exit 1
    end
    
    # Execute all metrics
    all_metrics = config.metrics
    all_metrics.each(&:run)
    
    # Filter only metrics with problems
    failed_metrics = all_metrics.select { |m| m.verify? && !m.ok? }
    all_ok = failed_metrics.empty?
    
    # Determine if we should send email based on email_send_on setting
    send_on = config.email_send_on
    should_send = case send_on
    when :always
      true
    when :only_failures
      !all_ok
    when :never
      false
    else
      !all_ok  # Default to :only_failures behavior
    end
    
    if should_send
      begin
        MaxPage::StatusMailer.status_report.deliver_now
        status_message = all_ok ? config.success_message : config.warning_message
        puts "✓ Status report email sent to #{config.email_to}"
        puts "  Status: #{status_message}"
        if !all_ok
          puts "  Failed metrics: #{failed_metrics.count}"
        end
      rescue => e
        puts "ERROR: Failed to send email: #{e.message}"
        puts e.backtrace.first(5).join("\n")
        exit 1
      end
    else
      if send_on == :never
        puts "Email sending is disabled (email_send_on: :never)"
      elsif all_ok && send_on == :only_failures
        puts "✓ All metrics are OK. No email sent (email_send_on: :only_failures)"
      end
      puts "  Total metrics checked: #{all_metrics.count}"
      puts "  Failed metrics: #{failed_metrics.count}"
    end
  end
end
