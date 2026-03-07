import { adminApi } from '../api.js';
import { fmtNum } from '../utils.js';
import { Chart, registerables } from 'chart.js';
Chart.register(...registerables);

export async function renderStats() {
  return {
    html: `
      <div>
        <div class="page-title">Statistiques</div>
        <div class="page-subtitle">Analyse de l'activité sur les 30 derniers jours</div>

        <div class="grid-2 mb-6">
          <div class="card">
            <div class="card-header"><span class="card-title">Nouvelles inscriptions</span></div>
            <div class="card-body"><div class="chart-container"><canvas id="chartSignups"></canvas></div></div>
          </div>
          <div class="card">
            <div class="card-header"><span class="card-title">Billets vendus par jour</span></div>
            <div class="card-body"><div class="chart-container"><canvas id="chartTickets"></canvas></div></div>
          </div>
        </div>

        <div class="card mb-6">
          <div class="card-header"><span class="card-title">Revenus journaliers (DZD)</span></div>
          <div class="card-body"><div class="chart-container" style="height:200px"><canvas id="chartRevenue"></canvas></div></div>
        </div>

        <div class="grid-3">
          <div class="card">
            <div class="card-body" style="text-align:center">
              <div style="font-size:11px;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px">Total inscriptions (30j)</div>
              <div id="sumSignups" class="stat-value" style="font-size:32px">—</div>
            </div>
          </div>
          <div class="card">
            <div class="card-body" style="text-align:center">
              <div style="font-size:11px;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px">Total billets (30j)</div>
              <div id="sumTickets" class="stat-value" style="font-size:32px;color:var(--success)">—</div>
            </div>
          </div>
          <div class="card">
            <div class="card-body" style="text-align:center">
              <div style="font-size:11px;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px">Revenus totaux (30j)</div>
              <div id="sumRevenue" class="stat-value" style="font-size:32px;color:var(--bleu-cyan)">—</div>
            </div>
          </div>
        </div>

        <div id="loadingMsg" class="loading-center" style="position:absolute;top:50%;left:50%;transform:translate(-50%,-50%)">
          <div class="spinner"></div>
        </div>
      </div>
    `,

    async bind(root) {
      let daily;
      try {
        daily = await adminApi.dailyStats();
      } catch (e) {
        root.querySelector('#loadingMsg').innerHTML = `<p style="color:var(--danger)">${e.message}</p>`;
        return;
      }
      root.querySelector('#loadingMsg').style.display = 'none';

      const labels  = daily.map(d => d.date.slice(5));
      const signups = daily.map(d => d.signups        || 0);
      const tickets = daily.map(d => d.tickets_sold   || 0);
      const revenue = daily.map(d => d.revenue_dzd    || 0);

      root.querySelector('#sumSignups').textContent = fmtNum(signups.reduce((a,b) => a+b, 0));
      root.querySelector('#sumTickets').textContent = fmtNum(tickets.reduce((a,b) => a+b, 0));
      root.querySelector('#sumRevenue').textContent = fmtNum(revenue.reduce((a,b) => a+b, 0)) + ' DZD';

      buildBar(root.querySelector('#chartSignups'), labels, signups, '#00ACC1', 'Inscriptions');
      buildBar(root.querySelector('#chartTickets'), labels, tickets, '#43A047', 'Billets');
      buildArea(root.querySelector('#chartRevenue'), labels, revenue, '#FB8C00', 'Revenus (DZD)');
    }
  };
}

function buildBar(canvas, labels, data, color, label) {
  new Chart(canvas, {
    type: 'bar',
    data: {
      labels,
      datasets: [{ label, data, backgroundColor: color + 'CC', borderRadius: 4, borderSkipped: false }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: { grid: { display: false }, ticks: { color: 'rgba(11,28,62,0.35)', font: { size: 10, family: 'Montserrat' }, maxTicksLimit: 8 }, border: { display: false } },
        y: { beginAtZero: true, ticks: { color: 'rgba(11,28,62,0.35)', font: { size: 10, family: 'Montserrat' }, maxTicksLimit: 5 }, grid: { color: 'rgba(11,28,62,0.05)' }, border: { display: false } }
      }
    }
  });
}

function buildArea(canvas, labels, data, color, label) {
  new Chart(canvas, {
    type: 'line',
    data: {
      labels,
      datasets: [{ label, data, borderColor: color, backgroundColor: color + '22', borderWidth: 2.5, fill: true, tension: 0.4, pointRadius: 0, pointHoverRadius: 5 }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: { grid: { display: false }, ticks: { color: 'rgba(11,28,62,0.35)', font: { size: 10, family: 'Montserrat' }, maxTicksLimit: 8 }, border: { display: false } },
        y: { beginAtZero: true, ticks: { color: 'rgba(11,28,62,0.35)', font: { size: 10, family: 'Montserrat' }, maxTicksLimit: 5 }, grid: { color: 'rgba(11,28,62,0.05)' }, border: { display: false } }
      }
    }
  });
}
