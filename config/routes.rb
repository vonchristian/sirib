Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "health" => "health#show", as: :health_check

  root "home#landing"

  # Auth
  resource :session
  resources :passwords, param: :token


  # App routes
  resources :members, only: [ :index, :show, :new, :create, :edit, :update ] do
    member do
      get :tab_overview
      get :tab_savings
      get :tab_time_deposits
      get :tab_loans
      get :tab_share_capital
      get :tab_settings
    end
    resource :transaction, only: [ :new, :create ], controller: "member_transactions" do
      post :preview
    end
  end
  resources :membership_applications, only: [ :index, :new, :show ], param: :uuid do
    member do
      get :edit
      patch :update
      post :approve
      get :download_pdf
    end
  end
  get "applications", to: "membership_applications#index", as: :applications

  get "dashboard", to: "dashboard#index"
  get "dashboard/manager", to: "dashboard#manager", as: :manager_dashboard
  get "dashboard/settings", to: "dashboard#settings"

  namespace :accounting do
    get "balance_sheet", to: "balance_sheet#index"
    get "income_statement", to: "income_statement#index"
    get "cash_flow", to: "cash_flow#index"
    get "trial_balance", to: "trial_balance#index"
    get "chart_of_accounts", to: "chart_of_accounts#index"
    get "chart_of_accounts/search", to: "chart_of_accounts#search", as: :search_chart_of_accounts
    get "chart_of_accounts/accounts", to: "chart_of_accounts#accounts", as: :accounts_chart_of_accounts
    resources :entries, only: [ :new, :create ]
    resources :journal_entries, only: [ :index, :new, :create, :show ] do
      collection do
        post :preview
        get :saved_filters
        post :search
        post :save_filter
        post :apply_filter
      end
      member do
        post :reverse
      end
    end
    resources :entry_templates, only: [ :index ]
    get "accounts/search", to: "accounts#search"
    resources :accounts, only: [ :show ], controller: "accounts" do
      collection do
        get :audit_entries
      end
    end
  end

  namespace :treasury do
    resources :cash_sessions, only: [ :index, :show ] do
      resources :closings, only: [ :new, :create ], controller: "cash_sessions/closings"
      member do
        get :download_pdf
        post :receive_from_vault
        post :return_to_vault
      end
    end
    resources :deposits, only: [ :index, :new, :create, :show ]
    resources :time_deposit_products
    resources :time_deposits, only: [ :index, :new, :create, :show ] do
      collection do
        post :preview
      end
    end
    resources :loans, only: [ :index ], controller: "loans" do
      member do
        post :disburse
        get :voucher
      end
    end
    resources :savings_products
    resources :savings_accounts, only: [ :index, :new, :create, :show ] do
      collection do
        get :taken_products
      end
      member do
        get :deposit
        post :preview_deposit
        post :confirm_deposit
        get :withdraw
        post :preview_withdraw
        post :confirm_withdraw
      end
    end
    resources :vault_transfers, only: [ :index ] do
      member do
        post :approve
        post :reject
      end
    end
    get "searches/members", to: "searches#members"
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
    resources :loans, only: [ :index, :show ] do
      resources :payments, only: [ :create ]
      member do
        get :restructure
        get :timeline
      end
    end
    resources :restructures, only: [ :new, :create, :show ] do
      member do
        post :submit
        post :approve
        post :reject
        post :execute
      end
      collection do
        post :simulate
      end
    end
    resources :restructure_cases, only: [ :index, :show ], controller: "restructure_cases"
    get "searches/members", to: "searches#members"
    get "searches/loan_products", to: "searches#loan_products"
  end

  namespace :lending do
    get "loan_aging", to: "loan_aging#index"
  end

  namespace :equity, path: :equity do
    resources :products
    resources :accounts, only: [ :index, :new, :create, :show ] do
      member do
        get :buy
        post :preview_buy
        post :confirm_buy
      end
    end
  end

  namespace :management do
    get "dashboard", to: "dashboard#index"

    resources :branches, except: [ :destroy ]
    resources :departments, except: [ :destroy ]
    resources :teams, except: [ :destroy ]

    resources :roles, only: [ :index, :show, :new, :create, :edit, :update ]
    resources :permissions, only: [ :index, :show ]
    resources :users, only: [ :index, :show, :edit, :update ] do
      resources :role_assignments, only: [ :new, :create, :destroy ], controller: "user_role_assignments"
    end

    resources :policies do
      member do
        post :activate
        post :deactivate
      end
    end

    resources :approval_workflows do
      resources :approval_requests, only: [ :index, :show ] do
        member do
          post :approve
          post :reject
        end
      end
    end

    resources :configurations, only: [ :index, :new, :create, :show, :edit, :update ] do
      member do
        post :approve
        post :activate
      end
    end

    resources :entry_templates do
      member do
        post :preview
        post :execute
      end
    end

    resources :audit_logs, only: [ :index, :show ]

    resources :restructures, only: [ :index, :show ], controller: "restructures" do
      member do
        post :approve
        post :reject
      end
    end
  end
end
