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
