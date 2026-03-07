export function fmtNum(n) {
  if (n === null || n === undefined) return '—';
  return Number(n).toLocaleString('fr-FR');
}

export function fmtDate(iso) {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' });
}

export function fmtDateTime(iso) {
  if (!iso) return '—';
  return new Date(iso).toLocaleString('fr-FR', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  });
}

export function timeAgo(iso) {
  const diff = Date.now() - new Date(iso).getTime();
  const m = Math.floor(diff / 60000);
  if (m < 1)  return 'à l\'instant';
  if (m < 60) return `il y a ${m} min`;
  const h = Math.floor(m / 60);
  if (h < 24) return `il y a ${h}h`;
  const d = Math.floor(h / 24);
  return `il y a ${d}j`;
}

export function activityIcon(kind) {
  if (kind === 'signup') return '🆕';
  if (kind === 'ticket') return '🎟';
  if (kind === 'event')  return '📅';
  return '📌';
}

export function roleBadge(role) {
  if (role === 'admin')     return `<span class="badge badge-cyan">admin</span>`;
  if (role === 'organizer') return `<span class="badge badge-orange">organisateur</span>`;
  return `<span class="badge badge-grey">participant</span>`;
}

export function verifiedBadge(v) {
  return v
    ? `<span class="badge badge-green">✓ Vérifié</span>`
    : `<span class="badge badge-red">Non vérifié</span>`;
}

export function progressBar(val, max) {
  const pct = max > 0 ? Math.min(100, Math.round((val / max) * 100)) : 0;
  return `
    <div style="font-size:11px;font-weight:700;color:var(--bleu-profond)">${val} / ${max}</div>
    <div class="progress-bar"><div class="progress-fill" style="width:${pct}%"></div></div>
  `;
}
