# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

# 参考:https://blog.cloud-acct.com/posts/u-rails-rackcors/

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins *Rails.application.credentials.config[:cors_origins]
    resource '*',
      headers: :any,
      expose: ['access-token', 'uid', 'client'], # 追加
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
