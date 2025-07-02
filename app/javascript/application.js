// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

function setupCurrentlyHacking() {
  const header = document.querySelector('.currently-hacking');
  // only if no existing event listener
  if (!header) { return }
  header.onclick = function() {
    const container = document.querySelector('.currently-hacking-container');
    if (container) {
      container.classList.toggle('visible');
    }
  }
}

function outta() {
  // we should figure out a better way of doing this rather than this shit ass way, but it works for now
  const modal = document.getElementById('logout-modal');
  const can = document.getElementById('cancel-logout');
  
  if (!modal || !can) return;
  modal.classList.remove('hidden');

  function logshow() {
    modal.classList.remove('pointer-events-none');
    modal.classList.remove('opacity-0');
    modal.querySelector('.bg-dark').classList.remove('scale-95');
    modal.querySelector('.bg-dark').classList.add('scale-100');
  }

  function logquit() {
    modal.classList.add('opacity-0');
    modal.querySelector('.bg-dark').classList.remove('scale-100');
    modal.querySelector('.bg-dark').classList.add('scale-95');
    setTimeout(() => {
      modal.classList.add('pointer-events-none');
    }, 300);
  }

  window.showLogout = logshow;

  can.addEventListener('click', logquit);

  modal.addEventListener('click', function(e) {
    if (e.target === modal) {
      logquit();
    }
  });

  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' && !modal.classList.contains('pointer-events-none')) {
      logquit();
    }
  });
}

// Handle both initial page load and subsequent Turbo navigations
document.addEventListener('turbo:load', function() {
  setupCurrentlyHacking();
  outta();
});
document.addEventListener('turbo:render', function() {
  setupCurrentlyHacking();
  outta();
});
document.addEventListener('DOMContentLoaded', function() {
  setupCurrentlyHacking();
  outta();
});
