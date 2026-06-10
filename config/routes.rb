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

  namespace :accounting do
    get "balance_sheet", to: "balance_sheet#index"
    get "income_statement", to: "income_statement#index"
    get "cash_flow", to: "cash_flow#index"
    get "chart_of_accounts", to: "chart_of_accounts#index"
    resources :entries, only: [:index, :new, :create, :show]
    get "accounts/search", to: "accounts#search"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
