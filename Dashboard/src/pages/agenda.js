import { adminApi } from '../api.js';
import { fmtNum } from '../utils.js';

const MONTHS_FR = ['Janvier','Février','Mars','Avril','Mai','Juin','Juillet','Août','Septembre','Octobre','Novembre','Décembre'];
const DAYS_FR   = ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'];

let _year, _month, _events, _root;

export async function renderAgenda() {
  const now = new Date();
  _year  = now.getFullYear();
  _month = now.getMonth();

  return {
    html: `
      <div>
        <div class="page-title">Agenda</div>
        <div class="page-subtitle">Calendrier des événements à venir</div>

        <div class="grid-2" style="gap:20px;align-items:start">
          <div class="card">
            <div class="card-body">
              <div class="calendar-nav">
                <button class="cal-nav-btn" id="prevMonth">‹</button>
                <div class="cal-month" id="calTitle">—</div>
                <button class="cal-nav-btn" id="nextMonth">›</button>
              </div>
              <div id="calGrid" class="calendar-grid">
                <div class="loading-center"><div class="spinner"></div></div>
              </div>
            </div>
          </div>

          <div>
            <div class="card">
              <div class="card-header">
                <span class="card-title" id="eventsListTitle">Événements du mois</span>
              </div>
              <div class="card-body" style="padding-top:8px">
                <div id="agendaList"><div class="loading-center"><div class="spinner"></div></div></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    `,

    async bind(root) {
      _root = root;

      try {
        const data = await adminApi.events(1, 500);
        _events = data.events || [];
      } catch {
        _events = [];
      }

      renderCalendar();
      renderEventList();

      root.querySelector('#prevMonth').addEventListener('click', () => {
        _month--;
        if (_month < 0) { _month = 11; _year--; }
        renderCalendar();
        renderEventList();
      });

      root.querySelector('#nextMonth').addEventListener('click', () => {
        _month++;
        if (_month > 11) { _month = 0; _year++; }
        renderCalendar();
        renderEventList();
      });
    }
  };
}

function renderCalendar() {
  if (!_root) return;
  const title = _root.querySelector('#calTitle');
  title.textContent = `${MONTHS_FR[_month]} ${_year}`;

  const firstDay = new Date(_year, _month, 1).getDay(); // 0=Sun
  const adjust   = (firstDay === 0 ? 6 : firstDay - 1); // Mon-first offset
  const daysInMonth = new Date(_year, _month + 1, 0).getDate();
  const prevDays    = new Date(_year, _month, 0).getDate();

  const today = new Date();
  const todayStr = `${today.getFullYear()}-${String(today.getMonth()+1).padStart(2,'0')}-${String(today.getDate()).padStart(2,'0')}`;

  // Build a map: dateStr → events count
  const evtMap = {};
  _events.forEach(e => {
    const d = new Date(e.event_date);
    const key = `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
    evtMap[key] = (evtMap[key] || 0) + 1;
  });

  let html = DAYS_FR.map(d => `<div class="cal-day-label">${d}</div>`).join('');

  // prev month
  for (let i = adjust - 1; i >= 0; i--) {
    html += `<div class="cal-day other-month"><span class="day-num">${prevDays - i}</span></div>`;
  }

  // current month
  for (let d = 1; d <= daysInMonth; d++) {
    const dateStr = `${_year}-${String(_month+1).padStart(2,'0')}-${String(d).padStart(2,'0')}`;
    const count   = evtMap[dateStr] || 0;
    const isToday = dateStr === todayStr;

    html += `
      <div class="cal-day ${isToday ? 'today' : ''} ${count > 0 ? 'has-events' : ''}" data-date="${dateStr}">
        <span class="day-num">${d}</span>
        ${count > 0 ? `<div class="day-dots">${'<div class="day-dot"></div>'.repeat(Math.min(count, 3))}</div>` : ''}
      </div>
    `;
  }

  // next month padding
  const total = adjust + daysInMonth;
  const remaining = total % 7 === 0 ? 0 : 7 - (total % 7);
  for (let d = 1; d <= remaining; d++) {
    html += `<div class="cal-day other-month"><span class="day-num">${d}</span></div>`;
  }

  _root.querySelector('#calGrid').innerHTML = html;

  // Click on a day → filter events
  _root.querySelectorAll('.cal-day[data-date]').forEach(el => {
    el.addEventListener('click', () => {
      const d = el.dataset.date;
      const dayEvts = _events.filter(e => new Date(e.event_date).toISOString().slice(0,10) === d);
      const title = _root.querySelector('#eventsListTitle');
      title.textContent = `Événements du ${d.slice(8)}/${d.slice(5,7)}`;
      renderEventList(dayEvts);
    });
  });
}

function renderEventList(list) {
  if (!_root) return;
  const el = _root.querySelector('#agendaList');
  const src = list || _events.filter(e => {
    const d = new Date(e.event_date);
    return d.getFullYear() === _year && d.getMonth() === _month;
  });

  const sorted = [...src].sort((a, b) => new Date(a.event_date) - new Date(b.event_date));
  const now = new Date();

  if (!sorted.length) {
    el.innerHTML = `<div class="empty-state"><div class="icon">📭</div>Aucun événement ce mois</div>`;
    return;
  }

  el.innerHTML = `
    <div class="agenda-event-list">
      ${sorted.map(e => {
        const dt    = new Date(e.event_date);
        const day   = String(dt.getDate()).padStart(2,'0');
        const month = MONTHS_FR[dt.getMonth()].slice(0,3).toUpperCase();
        const isPast = dt < now;
        const remaining = e.capacity - e.tickets_sold;
        return `
          <div class="agenda-event-card" style="${isPast ? 'opacity:.55' : ''}">
            <div class="agenda-event-date">
              <div class="day">${day}</div>
              <div class="month">${month}</div>
            </div>
            <div class="agenda-event-info">
              <div class="name">${e.title}</div>
              <div class="loc">${e.location || 'Lieu non précisé'}</div>
            </div>
            <div class="agenda-event-ticket">
              <div class="sold">${fmtNum(e.tickets_sold)}</div>
              <div class="cap">/ ${fmtNum(e.capacity)} places</div>
              ${remaining <= 0 && e.capacity > 0 ? `<span class="badge badge-red" style="font-size:9px;margin-top:2px">Complet</span>` : ''}
            </div>
          </div>
        `;
      }).join('')}
    </div>
  `;
}
