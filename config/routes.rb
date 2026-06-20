require_relative "../app/constraints/subdomain_constraint"

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Root domain — redirect to main cooperative subdomain
  constraints(NoSubdomain) do
    get "/" => redirect { |_, req| "http://main.#{req.host_with_port}" }
  end

  # Tenant subdomain — all routes
  constraints(SubdomainPresent) do
    root "dashboard#index"

    # Member Portal — prefixed with /portal
    scope :portal, module: :portal, as: :portal do
      resource :session, only: %i[new create destroy], controller: "sessions"
      scope :mfa, controller: "mfa", as: :mfa do
        get :challenge
        post :verify
      end

      scope :enrollment, controller: "enrollment", as: :enrollment do
        get ":token", action: :show, as: :start
        post "", action: :complete
      end

      get "dashboard", to: "dashboard#index"
      resources :announcements, only: %i[index show]
    end

    # Auth
    resource :session
    resources :passwords, param: :token
    resource :mfa, only: [] do
      get :setup, to: "mfa#setup"
      post :enable, to: "mfa#enable"
      get :challenge, to: "mfa#challenge"
      post :verify, to: "mfa#verify"
      post :disable, to: "mfa#disable"
      get :backup_codes, to: "mfa#backup_codes"
      get :step_up_challenge, to: "mfa#step_up_challenge"
      post :step_up_verify, to: "mfa#step_up_verify"
      get :devices, to: "mfa#devices"
      delete :devices, to: "mfa#revoke_all_devices", as: :revoke_all_devices
      delete "devices/:id", to: "mfa#revoke_device", as: :revoke_device
    end

    # App routes
    resources :members, only: [:index, :show, :new, :create] do
      member do
        post :toggle_portal_access
      end
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

    namespace :external do
      resources :banks do
        resources :accounts do
          resources :documents, only: [:index, :show, :new, :create, :destroy]
          resource :reconciliation, only: [:show], controller: "reconciliation" do
            post :allocate
            post :confirm_allocation
            post :reject_allocation
          end
        end
      end
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

    namespace :management do
      get "dashboard", to: "dashboard#index"
      get "executive_dashboard", to: "executive_dashboard#index"
      get "branch_performance", to: "branch_performance#index"
      get "risk_monitoring", to: "risk_monitoring#index"
      get "system_health", to: "system_health#index"

      resources :branches, except: [:destroy]
      resources :departments, except: [:destroy]
      resources :teams, except: [:destroy]

      resources :roles, only: [:index, :show, :new, :create, :edit, :update]
      resources :permissions, only: [:index, :show]
      resources :users, only: [:index, :show, :edit, :update] do
        resources :role_assignments, only: [:new, :create, :destroy], controller: "user_role_assignments"
      end

      resources :policies do
        member do
          post :activate
          post :deactivate
        end
      end

      resources :approval_workflows do
        resources :approval_requests, only: [:index, :show] do
          member do
            post :approve
            post :reject
          end
        end
      end

      resources :configurations, only: [:index, :new, :create, :show, :edit, :update] do
        member do
          post :approve
          post :activate
        end
      end

      resources :alerts, only: [:index, :show] do
        member do
          post :resolve
        end
      end

      resources :audit_logs, only: [:index, :show]

      get "settings", to: "settings#index"

      get "searches/branches", to: "searches#branches"
      get "searches/users", to: "searches#users"

      namespace :messaging do
        resources :messages, only: [:index, :show]
        resources :channels, only: [:index, :show, :update] do
          resources :providers, only: [:index, :new, :create, :show, :edit, :update, :destroy]
        end
      end
    end

    post "messaging/webhooks/receive", to: "messaging/webhooks#receive", as: :messaging_webhooks_receive
  end
end
