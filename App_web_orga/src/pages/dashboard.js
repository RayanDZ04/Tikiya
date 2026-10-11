import { orgaApi } from '../api.js';
import { fmtDZD, fmtInt } from '../utils.js';

// Instance de graphique courante, détruite avant d'en recréer une (re-navigation).
let soldChartInstance = null;

export async function renderDashboard() {
  const [summary, events] = await Promise.all([
    orgaApi.summary(),
    orgaApi.myEvents(),
  ]);

  // Stats par événement (pour le graphique).
  const stats = await Promise.all(
    events.map((e) =>
      orgaApi.eventStats(e.id).then((s) => ({ ...e, sold: s.sold, revenue: s.revenue }))
        .catch(() => ({ ...e, sold: 0, revenue: 0 }))
    )
  );
  const top = [...stats].sort((a, b) => b.sold - a.sold).slice(0, 8);

  const html = `
    <div class="page-title">Tableau de bord</div>
    <div class="page-sub">Vue d'ensemble de vos événements et de vos ventes, en temps réel.</div>

    <div class="kpi-grid">
      <div class="kpi dark">
        <div class="kpi-ic">▦</div>
        <div class="kpi-val">${fmtInt(summary.events)}</div>
        <div class="kpi-label">Événements</div>
      </div>
      <div class="kpi cyan">
        <div class="kpi-ic">🎟</div>
        <div class="kpi-val">${fmtInt(summary.total_sold)}</div>
        <div class="kpi-label">Billets vendus</div>
      </div>
      <div class="kpi green">
        <div class="kpi-ic">$</div>
        <div class="kpi-val">${fmtDZD(summary.total_revenue)}</div>
        <div class="kpi-label">Revenu réel</div>
      </div>
      <div class="kpi orange">
        <div class="kpi-ic">↗</div>
        <div class="kpi-val">${fmtDZD(summary.estimated_revenue)}</div>
        <div class="kpi-label">Estimation (places)</div>
      </div>
      <div class="kpi dark">
        <div class="kpi-ic">👥</div>
        <div class="kpi-val">${fmtInt(summary.total_capacity)}</div>
        <div class="kpi-label">Places totales</div>
      </div>
    </div>

    <div class="card">
      <div class="card-head"><div class="card-title">Billets vendus par événement</div></div>
      ${top.length ? `<div class="chart-box"><canvas id="soldChart"></canvas></div>`
        : `<div class="empty">Aucun événement pour le moment.</div>`}
    </div>
  `;

  async function bind() {
    if (!top.length) return;
    const { default: Chart } = await import('chart.js/auto');
    const ctx = document.getElementById('soldChart');
    if (!ctx) return;
    // Détruit le graphique précédent (évite "Canvas is already in use").
    if (soldChartInstance) { soldChartInstance.destroy(); soldChartInstance = null; }
    Chart.getChart(ctx)?.destroy();
    soldChartInstance = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: top.map((e) => truncate(e.title, 18)),
        datasets: [{
          label: 'Billets vendus',
          data: top.map((e) => e.sold),
          backgroundColor: '#00ACC1',
          borderRadius: 6,
          maxBarThickness: 46,
        }],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              afterLabel: (c) => {
                const e = top[c.dataIndex];
                return `Revenu : ${fmtDZD(e.revenue)} · Capacité : ${fmtInt(e.capacity)}`;
              },
            },
          },
        },
        scales: {
          y: { beginAtZero: true, ticks: { precision: 0 } },
          x: { grid: { display: false } },
        },
      },
    });
  }

  return { html, bind };
}

function truncate(s, n) {
  s = String(s || '');
  return s.length > n ? s.slice(0, n - 1) + '…' : s;
}
