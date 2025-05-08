// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

function setupCurrentlyHacking() {
  const container = document.querySelector('.currently-hacking-container');
  const header = container?.querySelector('.currently-hacking-header');
  if (container && header) {
    header.addEventListener('click', function() {
      container.classList.toggle('visible');
    });
  }
}

document.addEventListener("DOMContentLoaded", setupCurrentlyHacking);
document.addEventListener("turbo:load", setupCurrentlyHacking);
