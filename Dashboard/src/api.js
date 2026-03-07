// ── Local token store ─────────────────────────────────────────────────────────
const TOKEN_KEY = 'tikiya_boss_token';
const USER_KEY  = 'tikiya_boss_user';

export const auth = {
  getToken: () => localStorage.getItem(TOKEN_KEY),
  getUser:  () => { try { return JSON.parse(localStorage.getItem(USER_KEY) || 'null'); } catch { return null; } },
  setSession(token, user) {
    localStorage.setItem(TOKEN_KEY, token);
    localStorage.setItem(USER_KEY, JSON.stringify(user));
  },
  clear() {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
  },
  isLogged: () => !!localStorage.getItem(TOKEN_KEY),
};

// ── HTTP helpers ──────────────────────────────────────────────────────────────
const BASE = '/api';

async function request(method, path, body) {
  const token = auth.getToken();
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(`${BASE}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  if (res.status === 401) {
    auth.clear();
    window.location.hash = '#/login';
    throw new Error('Non autorisé');
  }
  if (!res.ok) {
    let detail = `Erreur ${res.status}`;
    try { const j = await res.json(); detail = j.detail || j.message || detail; } catch {}
    throw new Error(detail);
  }
  if (res.status === 204) return null;
  return res.json();
}

const get  = (path)       => request('GET', path);
const post = (path, body) => request('POST', path, body);

// ── Auth API ──────────────────────────────────────────────────────────────────
export const authApi = {
  async login(email, password) {
    const data = await post('/login', { email, password });
    // data.tokens.access_token + data.user (role check happens caller-side)
    return data;
  },
};

// ── Admin API ─────────────────────────────────────────────────────────────────
export const adminApi = {
  stats:      ()                         => get('/admin/stats'),
  activity:   ()                         => get('/admin/activity'),
  dailyStats: ()                         => get('/admin/daily-stats'),
  users:      (page = 1, limit = 20, search = '') =>
    get(`/admin/users?page=${page}&limit=${limit}${search ? `&search=${encodeURIComponent(search)}` : ''}`),
  events:     (page = 1, limit = 50)     => get(`/admin/events?page=${page}&limit=${limit}`),
};
