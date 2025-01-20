Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :merchants, only: [ :create ]
      resources :orders, only: [ :create ]
    end
  end
end
