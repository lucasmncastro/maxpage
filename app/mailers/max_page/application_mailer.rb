module MaxPage
  class ApplicationMailer < ActionMailer::Base
    default from: -> { MaxPage.config.email_from }
    layout "max_page/mailer"
  end
end
