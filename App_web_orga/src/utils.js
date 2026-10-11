// ── Formatage ───────────────────────────────────────────────────────────────
export const fmtDZD = (n) =>
  `${Number(n || 0).toLocaleString('fr-FR')} DZD`;

export const fmtInt = (n) => Number(n || 0).toLocaleString('fr-FR');

export function fmtDate(iso) {
  if (!iso) return '—';
  const d = new Date(iso);
  if (isNaN(d)) return '—';
  return d.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' });
}

export const pct = (n) => `${Math.round((n || 0) * 100)}%`;

export function escapeHtml(s) {
  return String(s ?? '').replace(/[&<>"']/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

// ── Exports ─────────────────────────────────────────────────────────────────
/**
 * Exporte un tableau de lignes (objets) en .xlsx.
 * rows: [{col: valeur, ...}], sheetName + fileName sans extension.
 */
export async function exportXlsx(rows, { fileName = 'export', sheetName = 'Données' } = {}) {
  const XLSX = await import('xlsx');
  const ws = XLSX.utils.json_to_sheet(rows);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, sheetName);
  XLSX.writeFile(wb, `${fileName}_${todayStamp()}.xlsx`);
}

/** Export CSV simple (séparateur ; pour Excel FR). */
export function exportCsv(rows, { fileName = 'export' } = {}) {
  if (!rows.length) return;
  const cols = Object.keys(rows[0]);
  const esc = (v) => {
    const s = String(v ?? '');
    return /[";\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  };
  const lines = [cols.join(';'), ...rows.map((r) => cols.map((c) => esc(r[c])).join(';'))];
  const blob = new Blob(['﻿' + lines.join('\n')], { type: 'text/csv;charset=utf-8;' });
  downloadBlob(blob, `${fileName}_${todayStamp()}.csv`);
}

function downloadBlob(blob, name) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = name;
  document.body.appendChild(a); a.click(); a.remove();
  URL.revokeObjectURL(url);
}

function todayStamp() {
  const d = new Date();
  const p = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}${p(d.getMonth() + 1)}${p(d.getDate())}`;
}
