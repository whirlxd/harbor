import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trustIndicator"]

  async convictUser(event) {
    event.preventDefault()
    const userId = event.currentTarget.dataset.userId
    
    const modal = document.createElement('div')
    modal.classList.add('cm')
    modal.innerHTML = `
      <div class="cm-content">
        <div class="cm-header">
          <h3>Set User Trust Level</h3>
          <button type="button" class="cm-close">&times;</button>
        </div>
        <div class="cm-body">
          <p>Choose a trust level for this user:</p>
          <div class="cos">
            <button type="button" class="co" data-value="red" data-level="1">
              🔴 Convicted (1)
            </button>
            <button type="button" class="co" data-value="yellow" data-level="0">
              🟡 Unscored (0)
            </button>
            <button type="button" class="co" data-value="green" data-level="2">
              🟢 Trusted (2)
            </button>
          </div>
        </div>
      </div>
    `
    document.body.appendChild(modal)

    const close = modal.querySelector('.cm-close')
    close.addEventListener('click', () => {
      document.body.removeChild(modal)
    })

    const buttons = modal.querySelectorAll('.co')
    buttons.forEach(btn => {
      btn.addEventListener('click', async () => {
        const level = btn.dataset.value
        await this.updateUserTrustLevel(userId, level)
        document.body.removeChild(modal)
      })
    })
  }

  async updateUserTrustLevel(userId, level) {
    try {
      const token = document.querySelector('meta[name="csrf-token"]')?.content;
      
      if (!token) {
        throw new Error('CSRF token not found');
      }
      
      const resp = await fetch(`/users/${userId}/update_trust_level`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': token
        },
        body: JSON.stringify({ trust_level: level })
      });

      if (resp.ok) {
        const cell = document.querySelector(`.admin-timeline-user-header-cell[data-user-id="${userId}"]`);
        if (cell) {
          cell.classList.remove('user-trust-red', 'user-trust-green');
          
          if (level === 'red') {
            cell.classList.add('user-trust-red');
          } else if (level === 'green') {
            cell.classList.add('user-trust-green');
          }
          
          const indicator = cell.querySelector('.user-trust-indicator');
          if (indicator) {
            if (level === 'red') {
              indicator.textContent = '🔴';
              indicator.title = 'Convicted';
            } else if (level === 'green') {
              indicator.textContent = '🟢';
              indicator.title = 'Trusted';
            } else {
              indicator.textContent = '';
              indicator.title = 'Unscored';
            }
          }
        }
        
        const notice = document.createElement('div');
        notice.classList.add('tln');
        notice.innerHTML = `trust set to ${level}`;
        document.body.appendChild(notice);
        
        setTimeout(() => {
          notice.remove();
        }, 3000);
      } else {
        const err = await resp.json();
        throw new Error(err.error);
      }
    } catch (error) {
      console.error(error);
    }
  }
}
