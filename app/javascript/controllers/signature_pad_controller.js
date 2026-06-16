import { Controller } from "@hotwired/stimulus"
import SignaturePad from "signature_pad"

export default class extends Controller {
  static targets = ["canvas", "hidden", "clearBtn", "preview", "emptyState"]
  static values = { color: { type: String, default: "#1f2937" } }

  connect() {
    this.resizeCanvas()
    this.pad = new SignaturePad(this.canvasTarget, {
      penColor: this.colorValue,
      backgroundColor: "rgb(255, 255, 255)",
    })
    this.pad.addEventListener("beginStroke", () => this.clearBtnTarget.classList.remove("hidden"))
  }

  resizeCanvas() {
    const ratio = Math.max(window.devicePixelRatio || 1, 1)
    const rect = this.canvasTarget.getBoundingClientRect()
    this.canvasTarget.width = rect.width * ratio
    this.canvasTarget.height = rect.height * ratio
    this.canvasTarget.getContext("2d").scale(ratio, ratio)
  }

  clear() {
    this.pad.clear()
    this.clearBtnTarget.classList.add("hidden")
    this.hiddenTarget.value = ""
    this.previewTarget.classList.add("hidden")
    this.emptyStateTarget.classList.remove("hidden")
  }

  save(event) {
    if (this.pad.isEmpty()) {
      this.clearBtnTarget.classList.add("hidden")
      return
    }

    event?.preventDefault()

    const dataUrl = this.pad.toDataURL("image/png")
    this.hiddenTarget.value = dataUrl

    this.previewTarget.src = dataUrl
    this.previewTarget.classList.remove("hidden")
    this.emptyStateTarget.classList.add("hidden")
    this.clearBtnTarget.classList.remove("hidden")
  }

  disconnect() {
    this.pad?.off()
  }
}
