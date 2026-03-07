import { adminApi } from '../api.js';
import { fmtDate, roleBadge, verifiedBadge, fmtNum } from '../utils.js';

let _page  = 1;
let _search = '';
let _root;
const LIMIT = 20;

export async function renderUsers() {
  return {
    html: `
      <div>
        <div class="page-title">Utilisateurs</div>
        <div class="page-subtitle">Gestion de tous les comptes de la plateforme</div>

        <div class="card">
          <div class="card-header">
            <span class="card-title">Liste des utilisateurs</span>
            <span class="count-badge" id="userCount">—</span>
          </div>
          <div class="card-body" style="padding-bottom:0">
            <div class="toolbar">
              <input class="search-input" id="userSearch" type="search" placeholder="Rechercher par email ou pseudo…" value="" />
              <select class="select-filter" id="roleFilter">
                <option value="">Tous les rôles</option>
                <option value="admin">Admin</option>
                <option value="organizer">Organisateur</option>
                <option value="user">Participant</option>
              </select>
            </div>
          </div>
          <div class="table-wrap" id="usersTable">
            <div class="loading-center"><div class="spinner"></div></div>
          </div>
          <div class="pagination" id="usersPagination"></div>
        </div>
      </div>
    `,

    async bind(root) {
      _root = root;
      _page = 1;
      _search = '';

      await loadUsers();

      // Debounced search
      let debTimer;
      root.querySelector('#userSearch').addEventListener('input', (e) => {
        clearTimeout(debTimer);
        debTimer = setTimeout(() => {
          _search = e.target.value.trim();
          _page = 1;
          loadUsers();
        }, 350);
      });

      root.querySelector('#roleFilter').addEventListener('change', () => {
        _page = 1;
        loadUsers();
      });
    }
  };
}

async function loadUsers() {
  if (!_root) return;
  const tableEl = _root.querySelector('#usersTable');
  tableEl.innerHTML = `<div class="loading-center"><div class="spinner"></div></div>`;

  let data;
  try {
    data = await adminApi.users(_page, LIMIT, _search);
  } catch (e) {
    tableEl.innerHTML = `<p style="color:var(--danger);padding:20px;">${e.message}</p>`;
    return;
  }

  const { users = [], total = 0 } = data;
  const roleFilter = _root.querySelector('#roleFilter')?.value || '';

  const filtered = roleFilter
    ? users.filter(u => u.role === roleFilter || (roleFilter === 'user' && u.role !== 'admin' && u.role !== 'organizer'))
    : users;

  _root.querySelector('#userCount').textContent = fmtNum(total);

  if (!filtered.length) {
    tableEl.innerHTML = `<div class="empty-state"><div class="icon">👤</div>Aucun utilisateur trouvé</div>`;
  } else {
    tableEl.innerHTML = `
      <table>
        <thead>
          <tr>
            <th>Email / Pseudo</th>
            <th>Rôle</th>
            <th>Email vérifié</th>
            <th>Inscription</th>
          </tr>
        </thead>
        <tbody>
          ${filtered.map(u => `
            <tr>
              <td>
                <div style="font-weight:700;">${u.email}</div>
                ${u.username ? `<div style="font-size:11px;color:var(--text-muted);">@${u.username}</div>` : ''}
              </td>
              <td>${roleBadge(u.role)}</td>
              <td>${verifiedBadge(u.email_verified)}</td>
              <td style="white-space:nowrap;">${fmtDate(u.created_at)}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
  }

  // Pagination
  const totalPages = Math.max(1, Math.ceil(total / LIMIT));
  renderPagination(_root.querySelector('#usersPagination'), _page, totalPages, (p) => {
    _page = p;
    loadUsers();
  });
}

function renderPagination(el, current, totalPages, onChange) {
  if (totalPages <= 1) { el.innerHTML = ''; return; }

  let pages = '';
  const maxPgShow = 5;
  let start = Math.max(1, current - 2);
  let end   = Math.min(totalPages, start + maxPgShow - 1);
  if (end - start < maxPgShow - 1) start = Math.max(1, end - maxPgShow + 1);

  for (let i = start; i <= end; i++) {
    pages += `<button class="page-btn ${i === current ? 'active' : ''}" data-p="${i}">${i}</button>`;
  }

  el.innerHTML = `
    <span class="page-info">${fmtNum((current - 1) * LIMIT + 1)}–${fmtNum(Math.min(current * LIMIT, current * LIMIT))} sur ${fmtNum(totalPages * LIMIT)}</span>
    <button class="page-btn" data-p="${current - 1}" ${current <= 1 ? 'disabled' : ''}>‹</button>
    ${pages}
    <button class="page-btn" data-p="${current + 1}" ${current >= totalPages ? 'disabled' : ''}>›</button>
  `;

  el.querySelectorAll('.page-btn[data-p]').forEach(btn => {
    btn.addEventListener('click', () => onChange(Number(btn.dataset.p)));
  });
}
