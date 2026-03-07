import './style.css';
import { auth } from './api.js';
import { renderSidebar } from './components/sidebar.js';
import { renderLogin }     from './pages/login.js';
import { renderDashboard } from './pages/dashboard.js';
import { renderUsers }     from './pages/users.js';
import { renderEvents }    from './pages/events.js';
import { renderStats }     from './pages/stats.js';
import { renderAgenda }    from './pages/agenda.js';

const PAGE_TITLES = {
  '#/':        'Dashboard',
  '#/users':   'Utilisateurs',
  '#/events':  'Événements',
  '#/stats':   'Statistiques',
  '#/agenda':  'Agenda',
};

async function router() {
  const appEl = document.getElementById('app');
  const hash  = window.location.hash || '#/';

  // ── Not logged in → login page
  if (!auth.isLogged() || hash === '#/login') {
    const { html, bind } = await renderLogin(() => {
      window.location.hash = '#/';
      router();
    });
    appEl.innerHTML = html;
    bind(appEl);
    return;
  }

  // ── Logged in → render layout
  const pageTitle = PAGE_TITLES[hash] || 'Dashboard';
  const user = auth.getUser();
  const initials = user?.email?.slice(0,2).toUpperCase() || 'AD';

  const sidebar = renderSidebar((newHash) => {
    window.location.hash = newHash;
    router();
  });

  appEl.innerHTML = `
    <div class="app-layout">
      ${sidebar.html}
      <div class="main-content">
        <header class="top-bar">
          <div class="top-bar-title">Tikiya<span style="color:var(--bleu-cyan)">!Boss</span></div>
          <div class="top-bar-right">
            <div style="font-size:12px;font-weight:600;color:var(--text-muted);">${pageTitle}</div>
            <div class="top-bar-avatar">${initials}</div>
          </div>
        </header>
        <main class="page-content" id="pageContent">
          <div class="loading-center"><div class="spinner"></div></div>
        </main>
      </div>
    </div>
  `;

  sidebar.bind(appEl);

  // ── Load page
  let page;
  try {
    switch (hash) {
      case '#/':       page = await renderDashboard(); break;
      case '#/users':  page = await renderUsers();     break;
      case '#/events': page = await renderEvents();    break;
      case '#/stats':  page = await renderStats();     break;
      case '#/agenda': page = await renderAgenda();    break;
      default:         page = await renderDashboard();
    }
  } catch (e) {
    document.getElementById('pageContent').innerHTML =
      `<p style="color:var(--danger);padding:24px;">${e.message}</p>`;
    return;
  }

  const pageEl = document.getElementById('pageContent');
  if (!pageEl) return;
  pageEl.innerHTML = page.html;
  pageEl.style.opacity = '0';
  requestAnimationFrame(() => {
    pageEl.style.transition = 'opacity 0.18s ease';
    pageEl.style.opacity = '1';
  });
  await page.bind?.(pageEl);
}

// ── Listen for hash changes
window.addEventListener('hashchange', router);
window.addEventListener('DOMContentLoaded', router);

// Kick off
router();
