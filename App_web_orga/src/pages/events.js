import { orgaApi } from '../api.js';
import { fmtDZD, fmtInt, fmtDate, pct, escapeHtml, exportXlsx, exportCsv } from '../utils.js';

export async function renderEvents() {
  const events = await orgaApi.myEvents();
  const rows = await Promise.all(
    events.map((e) =>
      orgaApi.eventStats(e.id)
        .then((s) => ({ ...e, sold: s.sold, revenue: s.revenue }))
        .catch(() => ({ ...e, sold: 0, revenue: 0 }))
    )
  );

  const html = `
    <div class="page-title">Mes événements</div>
    <div class="page-sub">Détail des ventes par événement — exportable pour votre comptabilité.</div>

    <div class="card">
      <div class="card-head">
        <div class="card-title">${fmtInt(rows.length)} événement(s)</div>
        <div class="toolbar">
          <button class="btn btn-primary btn-sm" id="btnXlsx">⬇ Exporter Excel</button>
          <button class="btn btn-ghost btn-sm" id="btnCsv">⬇ CSV</button>
        </div>
      </div>
      ${rows.length ? `
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Événement</th>
              <th>Date</th>
              <th class="num">Prix</th>
              <th class="num">Capacité</th>
              <th class="num">Vendus</th>
              <th class="num">Revenu réel</th>
              <th>Remplissage</th>
            </tr>
          </thead>
          <tbody>
            ${rows.map((e) => {
              const fill = e.capacity > 0 ? e.sold / e.capacity : 0;
              return `
              <tr>
                <td>
                  <div class="evt-title">${escapeHtml(e.title)}</div>
                  <div class="evt-meta">${escapeHtml(e.location || '—')} · ${escapeHtml(e.category || '')}</div>
                </td>
                <td>${fmtDate(e.event_date)}</td>
                <td class="num">${e.price > 0 ? fmtDZD(e.price) : 'Gratuit'}</td>
                <td class="num">${fmtInt(e.capacity)}</td>
                <td class="num"><span class="pill ok">${fmtInt(e.sold)}</span></td>
                <td class="num">${fmtDZD(e.revenue)}</td>
                <td>
                  <div style="display:flex;align-items:center;gap:8px;">
                    <div class="fill-bar"><i style="width:${Math.min(100, Math.round(fill*100))}%"></i></div>
                    <span class="evt-meta">${pct(fill)}</span>
                  </div>
                </td>
              </tr>`;
            }).join('')}
          </tbody>
        </table>
      </div>` : `<div class="empty">Vous n'avez pas encore créé d'événement.</div>`}
    </div>
  `;

  function toExportRows() {
    return rows.map((e) => ({
      'Événement': e.title,
      'Lieu': e.location || '',
      'Catégorie': e.category || '',
      'Date': fmtDate(e.event_date),
      'Prix (DZD)': e.price || 0,
      'Capacité': e.capacity || 0,
      'Billets vendus': e.sold || 0,
      'Revenu réel (DZD)': e.revenue || 0,
      'Revenu estimé (DZD)': (e.price || 0) * (e.capacity || 0),
      'Taux de remplissage (%)': e.capacity > 0 ? Math.round((e.sold / e.capacity) * 100) : 0,
    }));
  }

  function bind(root) {
    root.querySelector('#btnXlsx')?.addEventListener('click', async (ev) => {
      const b = ev.currentTarget; b.disabled = true; b.textContent = 'Export…';
      try { await exportXlsx(toExportRows(), { fileName: 'tikiya_evenements', sheetName: 'Événements' }); }
      finally { b.disabled = false; b.textContent = '⬇ Exporter Excel'; }
    });
    root.querySelector('#btnCsv')?.addEventListener('click', () => {
      exportCsv(toExportRows(), { fileName: 'tikiya_evenements' });
    });
  }

  return { html, bind };
}
