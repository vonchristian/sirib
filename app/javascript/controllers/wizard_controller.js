import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "step", "nextBtn", "backBtn", "submitBtn",
    "video", "preview", "capturePlaceholder", "webcamError", "profileInput",
    "counter", "currentStep", "photoCounter", "photoGallery",
    "stepper", "dotMobile"
  ]
  static values = { currentStep: { type: Number, default: 0 } }

  static stepNames = [
    "personal_details", "address_contact", "identifications",
    "sources_of_income", "signature_specimens", "profile_photos"
  ]

  connect() {
    this.currentStepValue = this.stepIndexFromURL()
    if (this.currentStepValue < 0) {
      const step = parseInt(this.element.dataset.currentStep, 10)
      this.currentStepValue = isNaN(step) ? 0 : Math.min(5, Math.max(0, step))
    }
    this.photos = []
    try {
      const existing = JSON.parse(this.profileInputTarget.value || "[]")
      if (Array.isArray(existing)) this.photos = existing
    } catch (e) {
      this.photos = []
    }
    this.updateStepper()
    this.updateMobileDots()
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
      const isVisible = index === this.currentStepValue
      step.classList.toggle("hidden", !isVisible)
      if (isVisible) {
        step.classList.remove("animate-fade-in-up")
        void step.offsetWidth
        step.classList.add("animate-fade-in-up")
      }
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

    if (this.currentStepValue === 4) {
      this.element.querySelector("[data-controller='signature-pad']")
        ?.dispatchEvent(new CustomEvent("signature-pad:resize"))
    }

    if (this.currentStepValue === 5) {
      this.startWebcam()
    } else {
      this.stopWebcam()
    }

    this.updateStepper()
    this.updateCounter()
    this.updateMobileDots()
    this.syncURL()
    this.updateCurrentStepField()
  }

  updateStepper() {
    if (!this.hasStepperTarget) return
    const current = this.currentStepValue

    this.stepperTarget.querySelectorAll("[data-step-index]").forEach((el) => {
      const idx = parseInt(el.dataset.stepIndex, 10)
      const circle = el.querySelector("[data-step-circle]")
      const number = el.querySelector("[data-step-number]")
      const check = el.querySelector("[data-step-check]")
      const label = el.querySelector("[data-step-label]")
      const connectors = el.querySelectorAll("[data-step-connector]")

      if (circle) {
        if (idx < current) {
          circle.className = "relative flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full border-2 text-xs font-semibold transition-all duration-300 bg-primary border-primary text-white"
          if (number) number.classList.add("hidden")
          if (check) { check.classList.remove("hidden"); check.classList.add("text-white") }
        } else if (idx === current) {
          circle.className = "relative flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full border-2 text-xs font-semibold transition-all duration-300 border-primary text-primary"
          if (number) { number.classList.remove("hidden"); number.classList.add("text-primary") }
          if (check) check.classList.add("hidden")
        } else {
          circle.className = "relative flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full border-2 text-xs font-semibold transition-all duration-300 border-border text-text-tertiary"
          if (number) { number.classList.remove("hidden"); number.classList.add("text-text-tertiary") }
          if (check) check.classList.add("hidden")
        }
      }

      if (label) {
        if (idx === current) {
          label.className = "mt-1.5 text-[11px] font-medium leading-tight text-center truncate max-w-[7rem] transition-colors duration-200 text-primary"
        } else if (idx < current) {
          label.className = "mt-1.5 text-[11px] font-medium leading-tight text-center truncate max-w-[7rem] transition-colors duration-200 text-text-tertiary"
        } else {
          label.className = "mt-1.5 text-[11px] font-medium leading-tight text-center truncate max-w-[7rem] transition-colors duration-200 text-text-tertiary/50"
        }
      }

      connectors.forEach((conn) => {
        if (idx < current) {
          conn.className = "flex-1 h-px bg-primary transition-colors duration-300"
        } else {
          conn.className = "flex-1 h-px bg-border dark:bg-gray-700 transition-colors duration-300"
        }
      })
    })
  }

  updateMobileDots() {
    if (!this.hasDotMobileTarget) return
    const current = this.currentStepValue
    this.dotMobileTargets.forEach((dot, idx) => {
      if (idx < current) {
        dot.className = "flex-1 h-1.5 rounded-full transition-colors duration-300 bg-primary"
      } else if (idx === current) {
        dot.className = "flex-1 h-1.5 rounded-full transition-colors duration-300 bg-primary"
      } else {
        dot.className = "flex-1 h-1.5 rounded-full transition-colors duration-300 bg-gray-200 dark:bg-gray-700"
      }
    })
  }

  stepIndexFromURL() {
    const name = new URL(window.location).searchParams.get("step")
    return name ? this.constructor.stepNames.indexOf(name) : -1
  }

  syncURL() {
    const name = this.constructor.stepNames[this.currentStepValue]
    const url = new URL(window.location)
    if (url.searchParams.get("step") !== name) {
      url.searchParams.set("step", name)
      history.replaceState({ step: this.currentStepValue }, "", url.toString())
    }
  }

  updateCurrentStepField() {
    if (this.hasCurrentStepTarget) {
      this.currentStepTarget.value = this.currentStepValue
    }
  }

  updateCounter() {
    const step = this.currentStepValue + 1
    const total = this.stepTargets.length
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `Step ${step} of ${total}`
    }
  }

  validateStep() {
    const currentStep = this.stepTargets[this.currentStepValue]
    const requiredFields = currentStep.querySelectorAll("[required]")
    let valid = true

    requiredFields.forEach((field) => {
      field.classList.remove("field-input-error")
      const errorMsg = field.closest(".field-group")?.querySelector(".field-error")
      if (errorMsg) errorMsg.remove()

      if (!field.value.trim()) {
        field.classList.add("field-input-error")
        valid = false
        const wrapper = field.closest(".field-group")
        if (wrapper) {
          const msg = document.createElement("p")
          msg.className = "field-error"
          appendErrorIcon(msg)
          msg.appendChild(document.createTextNode(" This field is required"))
          wrapper.appendChild(msg)
        }
      }
    })

    currentStep.querySelectorAll(".id-image-input").forEach((hidden) => {
      const wrapper = hidden.closest(".field-group")
      if (!wrapper) return
      const existing = wrapper.querySelector(".field-error")
      if (existing) existing.remove()
      wrapper.querySelector(".file-input-highlight")?.classList.remove("field-input-error")

      if (!hidden.value.trim()) {
        valid = false
        const highlight = wrapper.querySelector(".file-input-highlight")
        if (highlight) highlight.classList.add("field-input-error")
        const msg = document.createElement("p")
        msg.className = "field-error"
        appendErrorIcon(msg)
        msg.appendChild(document.createTextNode(" Please upload an image"))
        wrapper.appendChild(msg)
      }
    })

    if (!valid) {
      const firstInvalid = currentStep.querySelector(".field-input-error")
      firstInvalid?.focus()
    }

    return valid
  }

  addIdentification() {
    const container = document.getElementById("identifications")
    const lastEntry = container.querySelector(".identification-entry:last-of-type")
    if (lastEntry) {
      const clone = lastEntry.cloneNode(true)
      clone.querySelectorAll("input, select").forEach((el) => { el.value = "" })
      container.appendChild(clone)
    } else {
      container.insertAdjacentHTML("beforeend", this.identificationTemplate())
    }
  }

  addIncome() {
    const container = document.getElementById("sources-of-income")
    const lastEntry = container.querySelector(".income-entry:last-of-type")
    if (lastEntry) {
      const clone = lastEntry.cloneNode(true)
      clone.querySelectorAll("input, select").forEach((el) => { el.value = "" })
      container.appendChild(clone)
    } else {
      container.insertAdjacentHTML("beforeend", this.incomeTemplate())
    }
  }

  identificationTemplate() {
    const className = this.inputClass
    return '<div class="rounded-lg border border-border bg-surface-alt dark:border-gray-700 dark:bg-gray-800/50 p-4 identification-entry">' +
      '<div class="grid grid-cols-1 gap-4 sm:grid-cols-2">' +
        '<div class="field-group">' +
          '<label class="field-label">ID Type</label>' +
          '<select name="membership_application[identifications][][id_type]" required class="' + className + '">' +
            '<option value="">Select ID type</option>' +
            '<option value="BIR">Bir</option>' +
            '<option value="UMID">Umid</option>' +
            '<option value="Passport">Passport</option>' +
            '<option value="Driver\'s License">Driver\'s License</option>' +
            '<option value="PRC ID">Prc Id</option>' +
            '<option value="Postal ID">Postal Id</option>' +
            '<option value="Voter\'s ID">Voter\'s Id</option>' +
            '<option value="National ID">National Id</option>' +
            '<option value="Others">Others</option>' +
          '</select>' +
        '</div>' +
        '<div class="field-group">' +
          '<label class="field-label">ID Number</label>' +
          '<input type="text" name="membership_application[identifications][][id_number]" value="" required placeholder="ID number" class="' + className + '">' +
        '</div>' +
      '</div>' +
      '<div class="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2">' +
        '<div class="field-group">' +
          '<label class="field-label">Front of ID *</label>' +
          '<input type="hidden" name="membership_application[identifications][][front_image]" value="" class="id-image-input">' +
          '<input type="file" accept="image/*" data-action="change->wizard#handleIdImage" class="file-input-highlight ' + className + ' file:mr-3 file:rounded-md file:border-0 file:bg-primary file:px-3 file:py-1 file:text-xs file:font-medium file:text-white hover:file:bg-primary-700">' +
          '<div class="group relative">' +
            '<img class="id-image-preview mt-2 h-24 w-full rounded-md border border-border object-cover dark:border-gray-700 hidden">' +
            '<button type="button" data-action="click->image-modal#open" data-image-modal-group="id" class="id-image-enlarge absolute bottom-1 right-1 flex items-center gap-1 rounded-md bg-black/60 px-1.5 py-0.5 text-[10px] text-white opacity-0 group-hover:opacity-100 transition-opacity hover:bg-black/75 hidden">' +
              '<svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607zM13.5 10.5h-6m0 0h-3m3 0v-3m0 3v3" /></svg>' +
              'View Larger' +
            '</button>' +
          '</div>' +
        '</div>' +
        '<div class="field-group">' +
          '<label class="field-label">Back of ID *</label>' +
          '<input type="hidden" name="membership_application[identifications][][back_image]" value="" class="id-image-input">' +
          '<input type="file" accept="image/*" data-action="change->wizard#handleIdImage" class="file-input-highlight ' + className + ' file:mr-3 file:rounded-md file:border-0 file:bg-primary file:px-3 file:py-1 file:text-xs file:font-medium file:text-white hover:file:bg-primary-700">' +
          '<div class="group relative">' +
            '<img class="id-image-preview mt-2 h-24 w-full rounded-md border border-border object-cover dark:border-gray-700 hidden">' +
            '<button type="button" data-action="click->image-modal#open" data-image-modal-group="id" class="id-image-enlarge absolute bottom-1 right-1 flex items-center gap-1 rounded-md bg-black/60 px-1.5 py-0.5 text-[10px] text-white opacity-0 group-hover:opacity-100 transition-opacity hover:bg-black/75 hidden">' +
              '<svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607zM13.5 10.5h-6m0 0h-3m3 0v-3m0 3v3" /></svg>' +
              'View Larger' +
            '</button>' +
          '</div>' +
        '</div>' +
      '</div>' +
    '</div>'
  }

  handleIdImage(event) {
    const file = event.target.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
      const container = event.target.closest(".field-group")
      if (!container) return
      const hidden = container.querySelector(".id-image-input")
      if (hidden) hidden.value = e.target.result
      const preview = container.querySelector(".id-image-preview")
      if (preview) {
        preview.src = e.target.result
        preview.classList.remove("hidden")
      }
      const enlarge = container.querySelector(".id-image-enlarge")
      if (enlarge) enlarge.classList.remove("hidden")
    }
    reader.readAsDataURL(file)
  }

  get inputClass() {
    return "field-input"
  }

  incomeTemplate() {
    const className = this.inputClass
    return '<div class="rounded-lg border border-border bg-surface-alt dark:border-gray-700 dark:bg-gray-800/50 p-4 income-entry">' +
      '<div class="grid grid-cols-1 gap-4 sm:grid-cols-2">' +
        '<div class="field-group">' +
          '<label class="field-label">Source of Income</label>' +
          '<select name="membership_application[sources_of_income][][source_type]" required class="' + className + '">' +
            '<option value="">Select source</option>' +
            '<option value="Employment">Employment</option>' +
            '<option value="Self-Employed">Self-Employed</option>' +
            '<option value="Business">Business</option>' +
            '<option value="Remittances">Remittances</option>' +
            '<option value="Pension">Pension</option>' +
            '<option value="Investment">Investment</option>' +
            '<option value="Others">Others</option>' +
          '</select>' +
        '</div>' +
        '<div class="field-group">' +
          '<label class="field-label">Monthly Income (PHP)</label>' +
          '<input type="number" name="membership_application[sources_of_income][][monthly_income]" value="" required min="0" step="0.01" placeholder="0.00" class="' + className + '">' +
        '</div>' +
      '</div>' +
    '</div>'
  }

  capturePhoto() {
    const video = this.videoElement
    if (!video) return

    const canvas = document.createElement("canvas")
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight
    canvas.getContext("2d").drawImage(video, 0, 0)

    const dataUrl = canvas.toDataURL("image/jpeg", 0.9)
    this.photos.push(dataUrl)
    this.updatePhotosField()
    this.renderPhotoGallery()

    this.previewTarget.src = dataUrl
    this.previewTarget.classList.remove("hidden")
    setTimeout(() => {
      this.previewTarget.classList.add("hidden")
    }, 800)
  }

  removePhoto(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10)
    this.photos.splice(index, 1)
    this.updatePhotosField()
    this.renderPhotoGallery()
  }

  renderPhotoGallery() {
    const gallery = this.photoGalleryTarget
    gallery.innerHTML = ""

    this.photos.forEach((dataUrl, index) => {
      const wrapper = document.createElement("div")
      wrapper.className = "relative"

      const imgWrapper = document.createElement("div")
      imgWrapper.className = "group relative"

      const img = document.createElement("img")
      img.src = dataUrl
      img.className = "h-16 w-full rounded-md border border-border bg-gray-50 object-cover dark:border-gray-700"
      img.alt = `Photo ${index + 1}`

      const enlargeBtn = document.createElement("button")
      enlargeBtn.type = "button"
      enlargeBtn.dataset.action = "click->image-modal#open"
      enlargeBtn.dataset.imageModalGroup = "profile"
      enlargeBtn.className = "absolute bottom-1 right-1 flex items-center gap-1 rounded-md bg-black/60 px-1.5 py-0.5 text-[10px] text-white opacity-0 group-hover:opacity-100 transition-opacity hover:bg-black/75"
      enlargeBtn.innerHTML = '<svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607zM13.5 10.5h-6m0 0h-3m3 0v-3m0 3v3" /></svg> View Larger'

      const removeBtn = document.createElement("button")
      removeBtn.type = "button"
      removeBtn.dataset.index = index
      removeBtn.dataset.action = "wizard#removePhoto"
      removeBtn.className = "absolute -top-1.5 -right-1.5 flex h-5 w-5 items-center justify-center rounded-full bg-danger text-white text-xs opacity-0 group-hover:opacity-100 transition-opacity shadow-sm"
      removeBtn.innerHTML = "×"

      imgWrapper.appendChild(img)
      imgWrapper.appendChild(enlargeBtn)
      wrapper.appendChild(imgWrapper)
      wrapper.appendChild(removeBtn)

      const label = document.createElement("p")
      label.className = "mt-0.5 text-center text-[10px] text-text-tertiary dark:text-gray-500"
      label.textContent = `#${index + 1}`
      wrapper.appendChild(label)

      gallery.appendChild(wrapper)
    })

    if (this.hasPhotoCounterTarget) {
      this.photoCounterTarget.textContent = `${this.photos.length} captured`
    }
  }

  updatePhotosField() {
    this.profileInputTarget.value = JSON.stringify(this.photos)
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

function appendErrorIcon(msg) {
  const icon = document.createElementNS("http://www.w3.org/2000/svg", "svg")
  icon.setAttribute("viewBox", "0 0 24 24")
  icon.setAttribute("fill", "none")
  icon.setAttribute("stroke", "currentColor")
  icon.setAttribute("stroke-width", "1.5")
  icon.style.width = "1em"
  icon.style.height = "1em"
  icon.style.flexShrink = "0"
  const path = document.createElementNS("http://www.w3.org/2000/svg", "path")
  path.setAttribute("stroke-linecap", "round")
  path.setAttribute("stroke-linejoin", "round")
  path.setAttribute("d", "M12 9v3.75m9-.75a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9 3.75h.008v.008H12v-.008Z")
  icon.appendChild(path)
  msg.appendChild(icon)
}
