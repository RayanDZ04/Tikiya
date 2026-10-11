// ── Stockage local du token ────────────────────────────────────────────────
const TOKEN_KEY = 'tikiya_orga_token';
const USER_KEY = 'tikiya_orga_user';

export const auth = {
  getToken: () => localStorage.getItem(TOKEN_KEY),
  getUser: () => {
    try { return JSON.parse(localStorage.getItem(USER_KEY) || 'null'); } catch { return null; }
  },
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

// ── HTTP ────────────────────────────────────────────────────────────────────
const BASE = '/api';

/** Levée quand le serveur exige un code 2FA pour finir la connexion. */
export class TwoFactorRequired extends Error {
  constructor() { super('2FA_REQUIRED'); this.name = 'TwoFactorRequired'; }
}

async function request(method, path, body, { auth: useAuth = true } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (useAuth) {
    const token = auth.getToken();
    if (token) headers['Authorization'] = `Bearer ${token}`;
  }

  const res = await fetch(`${BASE}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  if (res.status === 401 && useAuth && auth.isLogged()) {
    auth.clear();
    window.location.hash = '#/login';
    throw new Error('Session expirée, reconnectez-vous.');
  }
  if (!res.ok) {
    let detail = `Erreur ${res.status}`;
    try { const j = await res.json(); detail = j.detail || j.message || detail; } catch {}
    const err = new Error(detail);
    err.status = res.status;
    throw err;
  }
  if (res.status === 204) return null;
  return res.json();
}

const get = (path) => request('GET', path);
const post = (path, body, opts) => request('POST', path, body, opts);

// ── Authentification ────────────────────────────────────────────────────────
export const authApi = {
  /** Connexion. Lève TwoFactorRequired si un code 2FA est nécessaire. */
  async login(email, password, totpCode) {
    try {
      return await post('/login', {
        email,
        password,
        ...(totpCode ? { totp_code: totpCode } : {}),
      }, { auth: false });
    } catch (e) {
      if (e.status === 403 && e.message === '2FA_REQUIRED') throw new TwoFactorRequired();
      throw e;
    }
  },
};

// ── API organisateur ────────────────────────────────────────────────────────
export const orgaApi = {
  summary: () => get('/payments/mine/summary'),
  myEvents: () => get('/events/my'),
  eventStats: (id) => get(`/payments/event/${id}`),
};
