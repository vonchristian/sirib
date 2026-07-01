import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

import WizardController from "controllers/wizard_controller"
application.register("wizard", WizardController)

import LoanWizardController from "controllers/loan_wizard_controller"
application.register("loan-wizard", LoanWizardController)

import TabsController from "controllers/tabs_controller"
application.register("tabs", TabsController)

import CashCountController from "controllers/cash_count_controller"
application.register("cash-count", CashCountController)

import AiSidebarController from "controllers/ai_sidebar_controller"
application.register("ai-sidebar", AiSidebarController)

import TransactionFormController from "controllers/transaction_form_controller"
application.register("transaction-form", TransactionFormController)

import RailController from "controllers/rail_controller"
application.register("rail", RailController)

import SidebarController from "controllers/sidebar_controller"
application.register("sidebar", SidebarController)

import ChartOfAccountsController from "controllers/chart_of_accounts_controller"
application.register("chart-of-accounts", ChartOfAccountsController)

import MemberAutocompleteController from "controllers/member_autocomplete_controller"
application.register("member-autocomplete", MemberAutocompleteController)

import RestructureFormController from "controllers/restructure_form_controller"
application.register("restructure-form", RestructureFormController)

