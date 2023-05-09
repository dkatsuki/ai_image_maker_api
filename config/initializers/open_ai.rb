OpenAI.configure do |config|
  config.access_token = Rails.application.credentials.config[:open_ai][:secret_key]
end