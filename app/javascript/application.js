// Entry point for the build script in your package.json
import "./controllers"
import "@hotwired/turbo-rails"

document.addEventListener('turbo:load', () => {
    // console.log("loaded");

    const closeMenuButton = document.querySelector('#closemobilebutton');
    const openMenuButton = document.querySelector('#openMenuButton');
    const rankingMenuButton = document.querySelector('#rankingMenuButton');
    const rankingMenuIcon = document.querySelector('#rankingMenuIcon');
    const rankingMobileButton = document.querySelector('#rankingMobileButton');
    const rankingMobileMenu = document.querySelector('#rankingMobileMenu');
    const rankingMobileMenuIcon = document.querySelector('#rankingMobileMenuIcon');

    const mobileMenu = document.querySelector('#mobileMenu');

    closeMenuButton.addEventListener('click', () => {
      mobileMenu.classList.add('hidden');
    });
    openMenuButton.addEventListener('click', () => {
      mobileMenu.classList.remove('hidden');
    });

    const toggleMenu = () => {
    //   console.log("toggleMenu");

      const isOpen = !rankingMenu.classList.contains('hidden');
      if (isOpen) {
        rankingMenu.classList.add('transition', 'ease-in', 'duration-150', 'opacity-0', 'translate-y-1');
        rankingMenu.classList.remove('opacity-100', 'translate-y-0');
      } else {
        rankingMenu.classList.add('transition', 'ease-out', 'duration-200', 'opacity-100', 'translate-y-0');
        rankingMenu.classList.remove('opacity-0', 'translate-y-1');
      }
      rankingMenu.classList.toggle('hidden');
      rankingMenuIcon.classList.toggle('rotate-180', isOpen);

      rankingMobileMenuIcon.classList.toggle('rotate-180', isOpen);
      rankingMobileMenu.classList.toggle('hidden', isOpen);
    };


    rankingMobileButton.addEventListener('click', () => {
      toggleMenu();
    });

    rankingMenuButton.addEventListener('click', () => {
      toggleMenu();
    });

    closeMenuButton.click();
  });
