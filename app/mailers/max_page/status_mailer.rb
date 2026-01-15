module MaxPage
  class StatusMailer < ApplicationMailer
    default from: -> { MaxPage.config.email_from }

    def status_report
      config = MaxPage.config
      
      # Execute all metrics
      all_metrics = config.metrics
      all_metrics.each(&:run)
      
      # Filter only metrics with problems (that have verify and are not ok)
      failed_metrics = all_metrics.select { |m| m.verify? && !m.ok? }
      
      # Group failed metrics by their group
      failed_metrics_without_group = failed_metrics.reject(&:group)
      failed_groups = config.groups.select do |group|
        group.metrics.any? { |m| m.verify? && !m.ok? }
      end.map do |group|
        {
          name: group.name,
          metrics: group.metrics.select { |m| m.verify? && !m.ok? }
        }
      end
      
      # Determine overall status
      all_ok = failed_metrics.empty?
      status_message = all_ok ? config.success_message : config.warning_message
      
      @title = config.title
      @status_message = status_message
      @all_ok = all_ok
      @failed_metrics = failed_metrics_without_group
      @failed_groups = failed_groups
      
      mail(
        to: config.email_to,
        subject: "[MaxPage] #{@title || 'Status Report'} - #{status_message}"
      )
    end
  end
end
