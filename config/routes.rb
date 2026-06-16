Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  root "dashboard#index"

  namespace :dashboard do
  end

  get "dashboard", to: "dashboard#index"
  get "dashboard/manager", to: "dashboard#manager", as: :manager_dashboard
  get "dashboard/treasurer", to: "dashboard#treasurer", as: :treasurer_dashboard
  get "dashboard/accountant", to: "dashboard#accountant", as: :accountant_dashboard
  get "dashboard/loan_officer", to: "dashboard#loan_officer", as: :loan_officer_dashboard
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

  namespace :treasury do
    resources :deposits, only: [:index, :new, :create, :show]
    resources :time_deposit_products
    resources :time_deposits, only: [:index, :new, :create, :show] do
      collection do
        post :preview
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
