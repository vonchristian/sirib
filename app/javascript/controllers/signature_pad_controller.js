import { Controller } from "@hotwired/stimulus"
import SignaturePad from "signature_pad"

export default class extends Controller {
  static targets = ["canvas", "hidden", "clearBtn", "counter", "gallery"]
  static values = { color: { type: String, default: "#1f2937" } }

  connect() {
    this.pad = new SignaturePad(this.canvasTarget, {
      penColor: this.colorValue,
      backgroundColor: "rgb(255, 255, 255)",
    })

    this.pad.addEventListener("beginStroke", () => {
      this.clearBtnTarget?.classList.remove("hidden")
    })

    this.specimens = []
    try {
      const existing = JSON.parse(this.hiddenTarget.value || "[]")
      if (Array.isArray(existing)) this.specimens = existing
    } catch (e) {
      this.specimens = []
    }

    this.renderGallery()
    this.element.addEventListener("signature-pad:resize", () => this.resizeCanvas())
    this.resizeObserver = new ResizeObserver(() => this.resizeCanvas())
    this.resizeObserver.observe(this.canvasTarget)
    setTimeout(() => this.resizeCanvas(), 50)
  }

  resizeCanvas() {
    const rect = this.canvasTarget.getBoundingClientRect()
    if (rect.width === 0 || rect.height === 0) return

    const ratio = Math.max(window.devicePixelRatio || 1, 1)
    const data = this.pad?.toData()

    this.canvasTarget.width = rect.width * ratio
    this.canvasTarget.height = rect.height * ratio
    this.canvasTarget.getContext("2d").scale(ratio, ratio)

    if (this.pad) {
      this.pad.clear()
      if (data && data.length > 0) this.pad.fromData(data)
    }
  }

  capture() {
    if (this.pad.isEmpty()) return

    const dataUrl = this.pad.toDataURL("image/png")
    this.specimens.push(dataUrl)
    this.updateHiddenField()
    this.pad.clear()
    this.clearBtnTarget?.classList.add("hidden")
    this.resizeCanvas()
    this.renderGallery()
  }

  remove(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10)
    this.specimens.splice(index, 1)
    this.updateHiddenField()
    this.renderGallery()
  }

  clear() {
    this.pad.clear()
    this.clearBtnTarget?.classList.add("hidden")
    this.resizeCanvas()
  }

  renderGallery() {
    const gallery = this.galleryTarget
    gallery.innerHTML = ""

    this.specimens.forEach((dataUrl, index) => {
      const wrapper = document.createElement("div")
      wrapper.className = "relative group"

      const img = document.createElement("img")
      img.src = dataUrl
      img.className = "h-16 w-full rounded-md border border-border bg-white object-contain dark:border-gray-700"
      img.alt = `Specimen ${index + 1}`

      const removeBtn = document.createElement("button")
      removeBtn.type = "button"
      removeBtn.dataset.index = index
      removeBtn.dataset.action = "signature-pad#remove"
      removeBtn.className = "absolute -top-1.5 -right-1.5 flex h-5 w-5 items-center justify-center rounded-full bg-danger text-white text-xs opacity-0 group-hover:opacity-100 transition-opacity shadow-sm"
      removeBtn.innerHTML = "×"

      wrapper.appendChild(img)
      wrapper.appendChild(removeBtn)

      const label = document.createElement("p")
      label.className = "mt-0.5 text-center text-[10px] text-text-tertiary dark:text-gray-500"
      label.textContent = `#${index + 1}`
      wrapper.appendChild(label)

      gallery.appendChild(wrapper)
    })

    this.counterTarget.textContent = `${this.specimens.length} of at least 3 captured`
  }

  updateHiddenField() {
    this.hiddenTarget.value = JSON.stringify(this.specimens)
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    this.pad?.off()
  }
}
