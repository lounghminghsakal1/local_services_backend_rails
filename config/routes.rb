Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  namespace :api do
    namespace :v1 do
      namespace :customer do
        post :signup, to: "auth#signup"
        post :login, to: "auth#login"
        resources :bookings, only: [ :create, :index, :show ] do
          member do
            post :search_decision
          end
        end
      end

      namespace :admin do
        post :login, to: "auth#login"
        resources :bookings, only: [ :show, :index ] do
          member do
            post :manual_assign
            post :broadcast
          end
        end
      end

      namespace :partner do
        post :signup, to: "auth#signup"
        post :login, to: "auth#login"
        resources :booking_offers, only: [ :show, :index ] do
          member do
            post :accept
            post :reject
            post :in_progress
            post :complete
          end
        end
      end
    end
  end
end
