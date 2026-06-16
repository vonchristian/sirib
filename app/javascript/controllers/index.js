import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

import WizardController from "controllers/wizard_controller"
application.register("wizard", WizardController)
