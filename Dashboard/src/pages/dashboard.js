import { adminApi } from '../api.js';
import { fmtDate, fmtNum, timeAgo, activityIcon } from '../utils.js';
import { Chart, registerables } from 'chart.js';
Chart.register(...registerables);

export async function renderDashboard() {
  return {
    html: `
      <div>
        <div class="page-title">Dashboard</div>
        <div class="page-subtitle">Vue d'ensemble de la plateforme Tikiya</div>

        <!-- KPI cards -->
        <div class="stat-grid" id="kpiGrid">
          <div class="loading-center"><div class="spinner"></div></div>
        </div>

        <!-- Charts + Activity -->
        <div class="grid-2 mb-6" id="midRow">
          <div class="card">
            <div class="card-header">
              <span class="card-title">Inscriptions (30 jours)</span>
            </div>
            <div class="card-body">
              <div class="chart-container"><canvas id="signupsChart"></canvas></div>
            </div>
          </div>
          <div class="card">
            <div class="card-header">
              <span class="card-title">Billets vendus (30 jours)</span>
            </div>
            <div class="card-body">
              <div class="chart-container"><canvas id="ticketsChart"></canvas></div>
            </div>
          </div>
        </div>

        <!-- Activity -->
        <div class="card">
          <div class="card-header">
            <span class="card-title">Activité récente</span>
          </div>
          <div class="card-body" id="activityFeed">
            <div class="loading-center"><div class="spinner"></div></div>
          </div>
        </div>
      </div>
    `,

    async bind(root) {
      let stats, activity, daily;
      try {
        [stats, activity, daily] = await Promise.all([
          adminApi.stats(),
          adminApi.activity(),
          adminApi.dailyStats(),
        ]);
      } catch (e) {
        root.querySelector('#kpiGrid').innerHTML = `<p style="color:var(--danger);padding:16px;">${e.message}</p>`;
        return;
      }

      // ── KPI Grid
      root.querySelector('#kpiGrid').innerHTML = `
        ${kpiCard('👥', 'Utilisateurs totaux',   fmtNum(stats.total_users))}
        ${kpiCard('🆕', 'Nouveaux aujourd\'hui', fmtNum(stats.new_users_today), '+' + stats.new_users_today + ' ce jour')}
        ${kpiCard('🎟', 'Billets vendus',         fmtNum(stats.total_tickets_sold))}
        ${kpiCard('📅', 'Évènements actifs',       fmtNum(stats.active_events))}
        ${kpiCard('💰', 'Revenus (DZD)',           fmtNum(stats.total_revenue_dzd) + ' DZD')}
        ${kpiCard('⏳', 'Billets en attente',      fmtNum(stats.pending_tickets))}
      `;

      // ── Charts
      const labels = (daily || []).map(d => d.date.slice(5)); // MM-DD
      const signups = (daily || []).map(d => d.signups || 0);
      const tickets = (daily || []).map(d => d.tickets_sold || 0);

      buildLineChart(root.querySelector('#signupsChart'), labels, signups, '#00ACC1', 'Inscriptions');
      buildLineChart(root.querySelector('#ticketsChart'), labels, tickets, '#43A047', 'Billets');

      // ── Activity feed
      if (!activity?.length) {
        root.querySelector('#activityFeed').innerHTML = `<div class="empty-state"><div class="icon">📭</div>Aucune activité récente</div>`;
        return;
      }
      root.querySelector('#activityFeed').innerHTML = `
        <div class="activity-list">
          ${activity.map(item => `
            <div class="activity-item">
              <div class="activity-dot dot-${item.kind}">${activityIcon(item.kind)}</div>
              <div class="activity-text">
                <div class="label">${item.label}</div>
                <div class="sub">${item.sub}</div>
              </div>
              <div class="activity-time">${timeAgo(item.at)}</div>
            </div>
          `).join('')}
        </div>
      `;
    }
  };
}

function kpiCard(emoji, label, value, delta = '') {
  return `
    <div class="stat-card">
      <div class="stat-icon">${emoji}</div>
      <div class="stat-label">${label}</div>
      <div class="stat-value">${value}</div>
      ${delta ? `<div class="stat-delta">${delta}</div>` : ''}
    </div>
  `;
}

function buildLineChart(canvas, labels, data, color, label) {
  new Chart(canvas, {
    type: 'line',
    data: {
      labels,
      datasets: [{
        label,
        data,
        borderColor: color,
        backgroundColor: color + '1A',
        borderWidth: 2.5,
        pointRadius: 0,
        pointHoverRadius: 4,
        fill: true,
        tension: 0.4,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: {
          grid: { display: false },
          ticks: { color: 'rgba(11,28,62,0.35)', font: { size: 10, family: 'Montserrat' }, maxTicksLimit: 8 },
          border: { display: false },
        },
        y: {
          beginAtZero: true,
          ticks: { color: 'rgba(11,28,62,0.35)', font: { size: 10, family: 'Montserrat' }, maxTicksLimit: 5 },
          grid: { color: 'rgba(11,28,62,0.05)' },
          border: { display: false },
        }
      }
    }
  });
}
