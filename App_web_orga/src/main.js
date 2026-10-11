import './style.css';
import { auth } from './api.js';
import { renderSidebar } from './components/sidebar.js';
import { renderLogin } from './pages/login.js';
import { renderDashboard } from './pages/dashboard.js';
import { renderEvents } from './pages/events.js';

const PAGE_TITLES = { '#/': 'Tableau de bord', '#/events': 'Mes événements' };

async function router() {
  const appEl = document.getElementById('app');
  const hash = window.location.hash || '#/';

  if (!auth.isLogged() || hash === '#/login') {
    const { html, bind } = renderLogin(() => { window.location.hash = '#/'; router(); });
    appEl.innerHTML = html;
    bind(appEl);
    return;
  }

  const pageTitle = PAGE_TITLES[hash] || 'Tableau de bord';
  const user = auth.getUser();
  const initials = user?.email?.slice(0, 2).toUpperCase() || 'OR';
  const sidebar = renderSidebar((newHash) => { window.location.hash = newHash; router(); });

  appEl.innerHTML = `
    <div class="app-layout">
      ${sidebar.html}
      <div class="main-content">
        <header class="top-bar">
          <div class="top-bar-title">Tikiya<span class="bang">!</span> PRO</div>
          <div style="display:flex;align-items:center;gap:12px;">
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

  let page;
  try {
    switch (hash) {
      case '#/events': page = await renderEvents(); break;
      case '#/': default: page = await renderDashboard();
    }
  } catch (e) {
    const el = document.getElementById('pageContent');
    if (el) el.innerHTML = `<p style="color:var(--danger);padding:24px;">${e.message}</p>`;
    return;
  }

  const pageEl = document.getElementById('pageContent');
  if (!pageEl) return;
  pageEl.innerHTML = page.html;
  await page.bind?.(pageEl);
}

window.addEventListener('hashchange', router);
// Les modules s'exécutent après le parsing du DOM : un seul appel suffit
// (éviter un double rendu concurrent, ex. DOMContentLoaded + appel direct).
router();
