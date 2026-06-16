import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "image", "counter", "prevNav", "nextNav", "title"]

  get groupLabel() {
    return {
      identifications: "Identification",
      signature: "Signature Specimen",
      profile: "Profile Photo",
    }[this._groupName] || this._groupName
  }

  connect() {
    this.images = []
    this.currentIndex = 0
  }

  imageSrcFor(trigger) {
    if (trigger.tagName === "IMG") return trigger.src
    const wrapper = trigger.closest(".group") || trigger.parentElement
    const img = wrapper?.querySelector("img")
    return img?.src || ""
  }

  open(event) {
    const trigger = event.currentTarget
    this._groupName = trigger.dataset.imageModalGroup || "default"
    this.images = [...this.element.querySelectorAll(`[data-image-modal-group="${this._groupName}"]`)]
    this.currentIndex = this.images.indexOf(trigger)
    if (this.currentIndex === -1) {
      this.images = [trigger]
      this.currentIndex = 0
    }
    this.renderImage()
    this.dialogTarget.showModal()
  }

  renderImage() {
    const trigger = this.images[this.currentIndex]
    if (!trigger) return
    this.imageTarget.src = this.imageSrcFor(trigger)
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.currentIndex + 1} / ${this.images.length}`
    }
    if (this.hasPrevNavTarget) {
      this.prevNavTarget.classList.toggle("opacity-30", this.currentIndex === 0)
      this.prevNavTarget.classList.toggle("pointer-events-none", this.currentIndex === 0)
    }
    if (this.hasNextNavTarget) {
      this.nextNavTarget.classList.toggle("opacity-30", this.currentIndex === this.images.length - 1)
      this.nextNavTarget.classList.toggle("pointer-events-none", this.currentIndex === this.images.length - 1)
    }
    if (this.hasTitleTarget) {
      this.titleTarget.textContent = `${this.groupLabel} ${this.currentIndex + 1} / ${this.images.length}`
    }
  }

  prev() {
    if (this.currentIndex > 0) {
      this.currentIndex--
      this.renderImage()
    }
  }

  next() {
    if (this.currentIndex < this.images.length - 1) {
      this.currentIndex++
      this.renderImage()
    }
  }

  navigate(event) {
    if (event.key === "ArrowRight") {
      event.preventDefault()
      this.next()
    } else if (event.key === "ArrowLeft") {
      event.preventDefault()
      this.prev()
    } else if (event.key === "Escape") {
      event.preventDefault()
      this.close()
    }
  }

  close() {
    this.dialogTarget.close()
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
