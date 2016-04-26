SampleApp::Application.config.middleware.use ExceptionNotification::Rack,
  :email => {
    :email_prefix => "[SampleApp] ",
    :sender_address => %{"notifier" <notifier@example.com>},
    :exception_recipients => ENV['EMAIL_ADDRESS']
  }
