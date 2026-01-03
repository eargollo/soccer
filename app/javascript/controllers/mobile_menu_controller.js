import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="mobile-menu"
export default class extends Controller {
  static targets = ["drawer", "backdrop", "hamburger"]

  connect() {
    // Close drawer when clicking on backdrop
    this.boundBackdropClick = this.handleBackdropClick.bind(this)
    this.backdropTarget.addEventListener("click", this.boundBackdropClick)
    
    // Close drawer on navigation (Turbo)
    this.boundTurboBeforeVisit = this.handleTurboBeforeVisit.bind(this)
    document.addEventListener("turbo:before-visit", this.boundTurboBeforeVisit)
    
    // Handle swipe gestures
    this.boundTouchStart = this.handleTouchStart.bind(this)
    this.boundTouchMove = this.handleTouchMove.bind(this)
    this.boundTouchEnd = this.handleTouchEnd.bind(this)
    
    this.drawerTarget.addEventListener("touchstart", this.boundTouchStart, { passive: true })
    this.drawerTarget.addEventListener("touchmove", this.boundTouchMove, { passive: true })
    this.drawerTarget.addEventListener("touchend", this.boundTouchEnd, { passive: true })
    
    // Track touch for swipe detection
    this.touchStartX = 0
    this.touchStartY = 0
    this.isDragging = false
    
    // Close drawer when clicking on links
    this.boundLinkClick = this.handleLinkClick.bind(this)
    this.drawerTarget.addEventListener("click", this.boundLinkClick)
    
    // Focus trap for keyboard navigation
    this.boundKeyDown = this.handleKeyDown.bind(this)
    this.previousActiveElement = null
  }

  disconnect() {
    this.backdropTarget.removeEventListener("click", this.boundBackdropClick)
    document.removeEventListener("turbo:before-visit", this.boundTurboBeforeVisit)
    this.drawerTarget.removeEventListener("touchstart", this.boundTouchStart)
    this.drawerTarget.removeEventListener("touchmove", this.boundTouchMove)
    this.drawerTarget.removeEventListener("touchend", this.boundTouchEnd)
    this.drawerTarget.removeEventListener("click", this.boundLinkClick)
    this.drawerTarget.removeEventListener("keydown", this.boundKeyDown)
  }

  toggle(event) {
    if (event) {
      event.stopPropagation()
    }
    if (this.isOpen()) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.drawerTarget.classList.remove("-translate-x-full")
    this.drawerTarget.classList.add("translate-x-0")
    this.backdropTarget.classList.remove("hidden")
    this.backdropTarget.classList.add("opacity-100")
    document.body.classList.add("overflow-hidden") // Prevent body scroll
    this.updateHamburgerState(true)
    this.updateAriaAttributes(true)
    
    // Focus trap: Save previous active element and focus first item
    this.previousActiveElement = document.activeElement
    this.drawerTarget.addEventListener("keydown", this.boundKeyDown)
    this.focusFirstItem()
    
    // Announce to screen readers
    this.announceToScreenReader("Menu opened")
  }

  close() {
    this.drawerTarget.classList.remove("translate-x-0")
    this.drawerTarget.classList.add("-translate-x-full")
    this.backdropTarget.classList.add("hidden")
    this.backdropTarget.classList.remove("opacity-100")
    document.body.classList.remove("overflow-hidden")
    this.updateHamburgerState(false)
    this.updateAriaAttributes(false)
    
    // Focus trap: Remove listener and restore focus
    this.drawerTarget.removeEventListener("keydown", this.boundKeyDown)
    if (this.previousActiveElement) {
      this.previousActiveElement.focus()
      this.previousActiveElement = null
    }
    
    // Announce to screen readers
    this.announceToScreenReader("Menu closed")
  }

  isOpen() {
    return this.drawerTarget.classList.contains("translate-x-0")
  }

  handleBackdropClick(event) {
    if (event.target === this.backdropTarget) {
      this.close()
    }
  }

  handleLinkClick(event) {
    // Close drawer when clicking on navigation links
    const link = event.target.closest("a")
    if (link && !link.closest("[data-dropdown-target='menu']")) {
      // Don't close if clicking inside a dropdown menu
      setTimeout(() => this.close(), 100)
    }
  }

  handleTurboBeforeVisit() {
    // Close drawer on navigation
    if (this.isOpen()) {
      this.close()
    }
  }

  handleTouchStart(event) {
    if (!this.isOpen()) return
    
    this.touchStartX = event.touches[0].clientX
    this.touchStartY = event.touches[0].clientY
    this.isDragging = false
  }

  handleTouchMove(event) {
    if (!this.isOpen()) return
    
    const touchX = event.touches[0].clientX
    const touchY = event.touches[0].clientY
    const deltaX = touchX - this.touchStartX
    const deltaY = touchY - this.touchStartY
    
    // Only start dragging if horizontal movement is greater than vertical
    if (Math.abs(deltaX) > Math.abs(deltaY) && Math.abs(deltaX) > 10) {
      this.isDragging = true
      
      // Only allow closing swipe (left direction)
      if (deltaX < 0) {
        const translateX = Math.max(deltaX, -this.drawerTarget.offsetWidth)
        this.drawerTarget.style.transform = `translateX(${translateX}px)`
      }
    }
  }

  handleTouchEnd(event) {
    if (!this.isOpen() || !this.isDragging) return
    
    const touchX = event.changedTouches[0].clientX
    const deltaX = touchX - this.touchStartX
    
    // If swiped more than 30% of drawer width, close it
    if (deltaX < -this.drawerTarget.offsetWidth * 0.3) {
      this.close()
    } else {
      // Snap back to open position
      this.drawerTarget.style.transform = ""
    }
    
    this.isDragging = false
  }

  updateHamburgerState(isOpen) {
    const hamburger = this.hamburgerTarget
    if (!hamburger) return
    
    const lines = hamburger.querySelectorAll(".hamburger-line")
    if (lines.length === 3) {
      if (isOpen) {
        // Transform to X
        lines[0].classList.add("rotate-45", "translate-y-2")
        lines[1].classList.add("opacity-0")
        lines[2].classList.add("-rotate-45", "-translate-y-2")
      } else {
        // Reset to hamburger
        lines[0].classList.remove("rotate-45", "translate-y-2")
        lines[1].classList.remove("opacity-0")
        lines[2].classList.remove("-rotate-45", "-translate-y-2")
      }
    }
  }

  updateAriaAttributes(isOpen) {
    this.hamburgerTarget?.setAttribute("aria-expanded", isOpen)
    this.drawerTarget.setAttribute("aria-hidden", !isOpen)
  }

  handleKeyDown(event) {
    // Escape key closes drawer
    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
      return
    }

    // Tab key navigation with focus trap
    if (event.key === "Tab") {
      const focusableElements = this.getFocusableElements()
      if (focusableElements.length === 0) return

      const firstElement = focusableElements[0]
      const lastElement = focusableElements[focusableElements.length - 1]

      if (event.shiftKey) {
        // Shift + Tab
        if (document.activeElement === firstElement) {
          event.preventDefault()
          lastElement.focus()
        }
      } else {
        // Tab
        if (document.activeElement === lastElement) {
          event.preventDefault()
          firstElement.focus()
        }
      }
    }
  }

  getFocusableElements() {
    // Get all focusable elements within the drawer
    const selector = 'a[href], button:not([disabled]), [tabindex]:not([tabindex="-1"])'
    return Array.from(this.drawerTarget.querySelectorAll(selector)).filter(
      (el) => !el.closest("[data-dropdown-target='menu']") || !el.closest("[data-dropdown-target='menu']").classList.contains("hidden")
    )
  }

  focusFirstItem() {
    const focusableElements = this.getFocusableElements()
    if (focusableElements.length > 0) {
      // Focus the first navigation link in the nav section
      const navSection = this.drawerTarget.querySelector("nav")
      if (navSection) {
        const firstNavLink = navSection.querySelector("a")
        if (firstNavLink) {
          firstNavLink.focus()
          return
        }
      }
      // Fallback to first focusable element
      focusableElements[0].focus()
    }
  }

  announceToScreenReader(message) {
    // Create a live region for screen reader announcements
    let announcer = document.getElementById("mobile-menu-announcer")
    if (!announcer) {
      announcer = document.createElement("div")
      announcer.id = "mobile-menu-announcer"
      announcer.setAttribute("role", "status")
      announcer.setAttribute("aria-live", "polite")
      announcer.setAttribute("aria-atomic", "true")
      announcer.className = "sr-only"
      document.body.appendChild(announcer)
    }
    announcer.textContent = message
    // Clear after announcement
    setTimeout(() => {
      announcer.textContent = ""
    }, 1000)
  }
}

