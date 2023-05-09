Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  get '/test', to: 'utility#test'
  post '/translations/to_english', to: 'translations#to_english'
  post '/translations/to_japanese', to: 'translations#to_japanese'
end
