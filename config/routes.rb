Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  root "dashboard#index"

  namespace :dashboard do
  end

  get "dashboard", to: "dashboard#index"
  get "dashboard/loans", to: "dashboard#loans"
  get "dashboard/payments", to: "dashboard#payments"
  get "dashboard/members", to: "dashboard#members"
  get "dashboard/tasks", to: "dashboard#tasks"
  get "dashboard/reports", to: "dashboard#reports"
  get "dashboard/settings", to: "dashboard#settings"

  get "up" => "rails/health#show", as: :rails_health_check
end
