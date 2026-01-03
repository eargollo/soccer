import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["menu", "button"]

  connect() {
    // Close dropdown when clicking outside (use capture phase to avoid conflicts)
    this.boundClickOutside = this.clickOutside.bind(this)
    document.addEventListener("click", this.boundClickOutside, true)
    
    // Keyboard navigation
    this.boundKeyDown = this.handleKeyDown.bind(this)
    this.buttonTarget.addEventListener("keydown", this.boundKeyDown)
    this.boundMenuKeyDown = this.handleMenuKeyDown.bind(this)
    this.menuTarget.addEventListener("keydown", this.boundMenuKeyDown)
    
    // Close dropdown when clicking on links (navigation)
    this.menuTarget.addEventListener("click", (event) => {
      if (event.target.closest("a")) {
        // Small delay to allow navigation to start
        setTimeout(() => this.close(), 100)
      }
    })
    
    // Track current focused item for arrow key navigation
    this.focusedIndex = -1
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside, true)
    this.buttonTarget.removeEventListener("keydown", this.boundKeyDown)
    this.menuTarget.removeEventListener("keydown", this.boundMenuKeyDown)
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
    
    // Update ARIA attributes for accessibility
    this.buttonTarget.setAttribute("aria-expanded", isOpen)
    if (isOpen) {
      this.menuTarget.setAttribute("aria-hidden", "false")
      // Focus first item when opening
      this.focusFirstItem()
    } else {
      this.menuTarget.setAttribute("aria-hidden", "true")
      this.focusedIndex = -1
    }
  }

  handleKeyDown(event) {
    // Enter or Space to open/close dropdown
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault()
      this.toggle(event)
    }
    // Escape to close dropdown
    else if (event.key === "Escape") {
      event.preventDefault()
      this.close()
      this.buttonTarget.focus()
    }
    // Arrow down to open and focus first item
    else if (event.key === "ArrowDown") {
      event.preventDefault()
      if (this.menuTarget.classList.contains("hidden")) {
        this.open()
      }
      this.focusFirstItem()
    }
  }

  handleMenuKeyDown(event) {
    if (this.menuTarget.classList.contains("hidden")) return

    const items = this.getFocusableItems()
    
    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.focusedIndex = Math.min(this.focusedIndex + 1, items.length - 1)
        this.focusItem(this.focusedIndex)
        break
      case "ArrowUp":
        event.preventDefault()
        this.focusedIndex = Math.max(this.focusedIndex - 1, 0)
        this.focusItem(this.focusedIndex)
        break
      case "Home":
        event.preventDefault()
        this.focusedIndex = 0
        this.focusItem(this.focusedIndex)
        break
      case "End":
        event.preventDefault()
        this.focusedIndex = items.length - 1
        this.focusItem(this.focusedIndex)
        break
      case "Escape":
        event.preventDefault()
        this.close()
        this.buttonTarget.focus()
        break
    }
  }

  getFocusableItems() {
    // Get all focusable items (links and buttons) in the dropdown
    return Array.from(this.menuTarget.querySelectorAll("a, button"))
  }

  focusFirstItem() {
    const items = this.getFocusableItems()
    if (items.length > 0) {
      this.focusedIndex = 0
      items[0].focus()
      this.menuTarget.addEventListener("keydown", this.boundMenuKeyDown)
    }
  }

  focusItem(index) {
    const items = this.getFocusableItems()
    if (items[index]) {
      items[index].focus()
    }
  }
}

