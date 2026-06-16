import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "step", "nextBtn", "backBtn", "submitBtn",
    "video", "preview", "capturePlaceholder", "webcamError", "profileInput",
    "currentStep"
  ]
  static values = { currentStep: { type: Number, default: 0 } }

  connect() {
    const step = parseInt(this.element.dataset.currentStep, 10)
    this.currentStepValue = isNaN(step) ? 0 : Math.min(4, Math.max(0, step))
    this.syncURL()
    this.showStep()
  }

  next() {
    if (this.validateStep()) {
      if (this.currentStepValue < this.stepTargets.length - 1) {
        this.currentStepValue++
        this.showStep()
      }
    }
  }

  back() {
    if (this.currentStepValue > 0) {
      this.currentStepValue--
      this.showStep()
    }
  }

  showStep() {
    this.stepTargets.forEach((step, index) => {
      step.classList.toggle("hidden", index !== this.currentStepValue)
    })

    if (this.hasBackBtnTarget) {
      this.backBtnTarget.classList.toggle("hidden", this.currentStepValue === 0)
    }

    if (this.hasNextBtnTarget) {
      this.nextBtnTarget.classList.toggle("hidden", this.currentStepValue === this.stepTargets.length - 1)
    }

    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.classList.toggle("hidden", this.currentStepValue !== this.stepTargets.length - 1)
    }

    if (this.currentStepValue === 3) {
      this.element.querySelector("[data-controller='signature-pad']")
        ?.dispatchEvent(new CustomEvent("signature-pad:resize"))
    }

    if (this.currentStepValue === 4) {
      this.startWebcam()
    } else {
      this.stopWebcam()
    }

    this.syncURL()
    this.updateCurrentStepField()
  }

  syncURL() {
    const url = new URL(window.location)
    if (parseInt(url.searchParams.get("step"), 10) !== this.currentStepValue) {
      url.searchParams.set("step", this.currentStepValue)
      history.replaceState({ step: this.currentStepValue }, "", url.toString())
    }
  }

  updateCurrentStepField() {
    if (this.hasCurrentStepTarget) {
      this.currentStepTarget.value = this.currentStepValue
    }
  }

  validateStep() {
    const currentStep = this.stepTargets[this.currentStepValue]
    const requiredFields = currentStep.querySelectorAll("[required]")
    let valid = true

    requiredFields.forEach((field) => {
      field.classList.remove("border-danger")
      const errorMsg = field.closest(".field-group")?.querySelector(".field-error")
      if (errorMsg) errorMsg.remove()

      if (!field.value.trim()) {
        field.classList.add("border-danger")
        valid = false
        const wrapper = field.closest(".field-group")
        if (wrapper) {
          const msg = document.createElement("p")
          msg.className = "field-error mt-1 text-xs text-danger"
          msg.textContent = "This field is required"
          wrapper.appendChild(msg)
        }
      }
    })

    if (!valid) {
      const firstInvalid = currentStep.querySelector(".border-danger")
      firstInvalid?.focus()
    }

    return valid
  }

  capturePhoto() {
    const video = this.videoElement
    if (!video) return

    const canvas = document.createElement("canvas")
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight
    canvas.getContext("2d").drawImage(video, 0, 0)

    const dataUrl = canvas.toDataURL("image/jpeg", 0.9)
    this.profileInputTarget.value = dataUrl
    this.previewCapturedPhoto(dataUrl)
  }

  previewCapturedPhoto(dataUrl) {
    const preview = this.previewTarget
    preview.src = dataUrl
    preview.classList.remove("hidden")
    this.capturePlaceholderTarget?.classList.add("hidden")
  }

  retakePhoto() {
    this.previewTarget.classList.add("hidden")
    this.capturePlaceholderTarget?.classList.add("hidden")
    this.profileInputTarget.value = ""
  }

  startWebcam() {
    if (this.stream) return

    navigator.mediaDevices.getUserMedia({ video: { width: 640, height: 480, facingMode: "user" } })
      .then((stream) => {
        this.stream = stream
        if (this.hasVideoTarget) {
          this.videoTarget.srcObject = stream
          this.videoTarget.play()
          this.capturePlaceholderTarget?.classList.add("hidden")
        }
      })
      .catch(() => {
        if (this.hasWebcamErrorTarget) {
          this.webcamErrorTarget.classList.remove("hidden")
        }
      })
  }

  stopWebcam() {
    if (this.stream) {
      this.stream.getTracks().forEach((track) => track.stop())
      this.stream = null
    }
  }

  disconnect() {
    this.stopWebcam()
  }

  get videoElement() {
    return this.videoTarget
  }
}
