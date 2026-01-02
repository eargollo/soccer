import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["menu", "button"]

  connect() {
    // Close dropdown when clicking outside (use capture phase to avoid conflicts)
    this.boundClickOutside = this.clickOutside.bind(this)
    document.addEventListener("click", this.boundClickOutside, true)
    
    // Close dropdown when clicking on links (navigation)
    this.menuTarget.addEventListener("click", (event) => {
      if (event.target.closest("a")) {
        // Small delay to allow navigation to start
        setTimeout(() => this.close(), 100)
      }
    })
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside, true)
  }

  toggle(event) {
    // Prevent the click from bubbling to document (which would trigger clickOutside)
    if (event) {
      event.stopPropagation()
    }
    this.menuTarget.classList.toggle("hidden")
    this.updateButtonState()
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    this.updateButtonState()
  }

  close() {
    this.menuTarget.classList.add("hidden")
    this.updateButtonState()
  }

  clickOutside(event) {
    // Don't close if clicking inside the dropdown element or button
    const clickedInside = this.element.contains(event.target) || 
                          this.buttonTarget.contains(event.target)
    if (!clickedInside && !this.menuTarget.classList.contains("hidden")) {
      this.close()
    }
  }

  updateButtonState() {
    const isOpen = !this.menuTarget.classList.contains("hidden")
    const chevron = this.buttonTarget.querySelector(".chevron")
    if (chevron) {
      chevron.classList.toggle("rotate-180", isOpen)
    }
  }
}

