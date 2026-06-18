Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  root "dashboard#index"

  resources :members, only: [:index, :show, :new, :create] do
    resource :transaction, only: [:new, :create], controller: "member_transactions" do
      post :preview
    end
  end
  resources :membership_applications, only: [:index, :new, :show], param: :uuid do
    member do
      get :edit
      patch :update
      post :approve
      get :download_pdf
    end
  end
  get "applications", to: "membership_applications#index", as: :applications

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
    resources :cash_sessions, only: [:index, :show] do
      resources :closings, only: [:new, :create], controller: "cash_sessions/closings"
      member do
        get :download_pdf
        post :receive_from_vault
        post :return_to_vault
      end
    end
    resources :deposits, only: [:index, :new, :create, :show]
    resources :time_deposit_products
    resources :time_deposits, only: [:index, :new, :create, :show] do
      collection do
        post :preview
      end
    end
    resources :loans, only: [:index], controller: "loans" do
      member do
        post :disburse
        get :voucher
      end
    end
    resources :savings_products
    resources :savings_accounts, only: [:index, :new, :create, :show] do
      member do
        get :deposit
        post :preview_deposit
        post :confirm_deposit
        get :withdraw
        post :preview_withdraw
        post :confirm_withdraw
      end
    end
    resources :vault_transfers, only: [:index] do
      member do
        post :approve
        post :reject
      end
    end
    get "searches/savings_accounts", to: "searches#savings_accounts"
  end

  namespace :loans do
    resources :products
    resources :applications, param: :uuid do
      member do
        get :edit
        patch :update
        post :submit
        get :download_pdf
      end
    end
    resources :loans, only: [:index, :show] do
      resources :payments, only: [:create]
    end
    get "searches/members", to: "searches#members"
    get "searches/loan_products", to: "searches#loan_products"
  end

  namespace :equity, path: :equity do
    resources :products
    resources :accounts, only: [:index, :new, :create, :show] do
      member do
        get :buy
        post :preview_buy
        post :confirm_buy
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
