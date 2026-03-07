import { auth } from '../api.js';

const ROUTES = [
  { hash: '#/',           label: 'Dashboard',    icon: dashIcon()  },
  { hash: '#/users',      label: 'Utilisateurs', icon: usersIcon() },
  { hash: '#/events',     label: 'Événements',   icon: eventsIcon()},
  { hash: '#/stats',      label: 'Statistiques', icon: statsIcon() },
  { hash: '#/agenda',     label: 'Agenda',       icon: agendaIcon()},
];

export function renderSidebar(onNavigate) {
  const activeHash = window.location.hash || '#/';

  const nav = ROUTES.map(r => `
    <div class="nav-item ${activeHash === r.hash ? 'active' : ''}" data-hash="${r.hash}">
      ${r.icon}
      <span>${r.label}</span>
    </div>
  `).join('');

  const user = auth.getUser();
  const initials = user?.email?.slice(0, 2).toUpperCase() || 'AD';

  const html = `
    <aside class="sidebar" id="sidebar">
      <div class="sidebar-brand">
        <div class="brand-name">Tikiya<span>!Boss</span></div>
        <div class="brand-sub">Admin Panel</div>
      </div>
      <nav class="sidebar-nav">
        <div class="sidebar-section-label">Navigation</div>
        ${nav}
      </nav>
      <div class="sidebar-bottom">
        <div style="display:flex;align-items:center;gap:10px;margin-bottom:12px;padding:0 4px;">
          <div class="top-bar-avatar">${initials}</div>
          <div>
            <div style="font-size:12px;font-weight:700;color:#fff;">${user?.email || 'Admin'}</div>
            <div style="font-size:10px;color:rgba(255,255,255,0.35);text-transform:uppercase;letter-spacing:1px;">Administrateur</div>
          </div>
        </div>
        <button class="logout-btn" id="logoutBtn">
          ${logoutIcon()}
          <span>Déconnexion</span>
        </button>
      </div>
    </aside>
  `;

  return { html, bind(root) {
    root.querySelectorAll('.nav-item[data-hash]').forEach(el => {
      el.addEventListener('click', () => {
        window.location.hash = el.dataset.hash;
        onNavigate(el.dataset.hash);
      });
    });
    root.querySelector('#logoutBtn')?.addEventListener('click', () => {
      auth.clear();
      window.location.hash = '#/login';
      onNavigate('#/login');
    });
  }};
}

// ── SVG icons ─────────────────────────────────────────────────────────────────
function dashIcon()  { return `<svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg>`; }
function usersIcon() { return `<svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>`; }
function eventsIcon(){ return `<svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>`; }
function statsIcon() { return `<svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>`; }
function agendaIcon(){ return `<svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/><path d="M8 14h.01M12 14h.01M16 14h.01M8 18h.01M12 18h.01"/></svg>`; }
function logoutIcon(){ return `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>`; }
