Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  post '/signup', to: 'auth#signup'
  post '/login', to: 'auth#login'
  get '/protected', to: 'test#protected'
  get '/users/:id', to: 'users#show'
  get '/users', to: 'users#index'
  patch '/users/:id', to: 'users#update'

  resources :plans, except: [:new, :edit, :destroy]
  resources :activities, except: [:new, :edit, :destroy]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
