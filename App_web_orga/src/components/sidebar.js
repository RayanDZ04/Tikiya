import { auth } from '../api.js';

const ITEMS = [
  { hash: '#/', icon: '▦', label: 'Tableau de bord' },
  { hash: '#/events', icon: '🎟', label: 'Mes événements' },
];

export function renderSidebar(navigate) {
  const current = window.location.hash || '#/';
  const user = auth.getUser();

  const html = `
    <aside class="sidebar">
      <div class="sidebar-logo">Tikiya<span class="bang">!</span> <span class="pro">PRO</span></div>
      ${ITEMS.map((it) => `
        <div class="nav-item ${it.hash === current ? 'active' : ''}" data-hash="${it.hash}">
          <span class="ic">${it.icon}</span><span>${it.label}</span>
        </div>
      `).join('')}
      <div class="sidebar-spacer"></div>
      <div class="sidebar-user">${user?.email || ''}</div>
      <div class="nav-item logout-btn" id="logoutBtn">
        <span class="ic">⎋</span><span>Se déconnecter</span>
      </div>
    </aside>
  `;

  function bind(root) {
    root.querySelectorAll('.nav-item[data-hash]').forEach((el) => {
      el.addEventListener('click', () => navigate(el.dataset.hash));
    });
    const logout = root.querySelector('#logoutBtn');
    if (logout) logout.addEventListener('click', () => {
      auth.clear();
      window.location.hash = '#/login';
      window.location.reload();
    });
  }

  return { html, bind };
}
