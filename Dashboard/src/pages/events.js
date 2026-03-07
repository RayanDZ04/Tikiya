import { adminApi } from '../api.js';
import { fmtDate, fmtNum, progressBar } from '../utils.js';

export async function renderEvents() {
  return {
    html: `
      <div>
        <div class="page-title">Événements</div>
        <div class="page-subtitle">Tous les événements créés sur la plateforme</div>

        <div class="card">
          <div class="card-header">
            <span class="card-title">Liste des événements</span>
            <span class="count-badge" id="eventsCount">—</span>
          </div>
          <div class="card-body" style="padding-bottom:0">
            <div class="toolbar">
              <input class="search-input" id="evtSearch" type="search" placeholder="Filtrer par nom ou lieu…" />
              <select class="select-filter" id="evtStatus">
                <option value="">Tous</option>
                <option value="upcoming">À venir</option>
                <option value="past">Passés</option>
              </select>
            </div>
          </div>
          <div class="table-wrap" id="eventsTable">
            <div class="loading-center"><div class="spinner"></div></div>
          </div>
        </div>
      </div>
    `,

    async bind(root) {
      let all = [];
      try {
        const data = await adminApi.events(1, 200);
        all = data.events || [];
        root.querySelector('#eventsCount').textContent = fmtNum(data.total);
      } catch (e) {
        root.querySelector('#eventsTable').innerHTML = `<p style="color:var(--danger);padding:20px;">${e.message}</p>`;
        return;
      }

      const now = new Date();
      function renderTable(list) {
        if (!list.length) {
          root.querySelector('#eventsTable').innerHTML = `<div class="empty-state"><div class="icon">📅</div>Aucun événement trouvé</div>`;
          return;
        }
        root.querySelector('#eventsTable').innerHTML = `
          <table>
            <thead>
              <tr>
                <th>Événement</th>
                <th>Lieu</th>
                <th>Date</th>
                <th>Prix</th>
                <th>Billets vendus</th>
                <th>Revenus</th>
                <th>Statut</th>
              </tr>
            </thead>
            <tbody>
              ${list.map(e => {
                const isPast = new Date(e.event_date) < now;
                const remaining = e.capacity - e.tickets_sold;
                return `
                  <tr>
                    <td>
                      <div style="font-weight:700;max-width:220px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${e.title}</div>
                      <div style="font-size:10px;color:var(--text-muted)">ID: ${e.id.slice(0,8)}…</div>
                    </td>
                    <td style="white-space:nowrap;">${e.location || '—'}</td>
                    <td style="white-space:nowrap;">${fmtDate(e.event_date)}</td>
                    <td style="white-space:nowrap;">${e.price > 0 ? fmtNum(e.price) + ' DZD' : '<span class="badge badge-green">Gratuit</span>'}</td>
                    <td>
                      ${e.capacity > 0 ? progressBar(e.tickets_sold, e.capacity) : `<span style="font-weight:700;">${fmtNum(e.tickets_sold)}</span>`}
                    </td>
                    <td style="white-space:nowrap;font-weight:700;">${fmtNum(e.revenue_dzd)} DZD</td>
                    <td>
                      ${isPast
                        ? `<span class="badge badge-grey">Terminé</span>`
                        : remaining <= 0
                          ? `<span class="badge badge-red">Complet</span>`
                          : `<span class="badge badge-green">Actif</span>`}
                    </td>
                  </tr>
                `;
              }).join('')}
            </tbody>
          </table>
        `;
      }

      function filter() {
        const search = root.querySelector('#evtSearch').value.toLowerCase();
        const status = root.querySelector('#evtStatus').value;
        let list = all;
        if (search) list = list.filter(e => e.title.toLowerCase().includes(search) || e.location?.toLowerCase().includes(search));
        if (status === 'upcoming') list = list.filter(e => new Date(e.event_date) >= now);
        if (status === 'past')     list = list.filter(e => new Date(e.event_date) < now);
        renderTable(list);
      }

      renderTable(all);

      let deb;
      root.querySelector('#evtSearch').addEventListener('input', () => { clearTimeout(deb); deb = setTimeout(filter, 250); });
      root.querySelector('#evtStatus').addEventListener('change', filter);
    }
  };
}
