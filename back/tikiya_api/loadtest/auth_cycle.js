import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: Number(__ENV.VUS || 50),
  duration: __ENV.DURATION || '2m',
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<1500'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://127.0.0.1:8080';
const TEST_PASSWORD = __ENV.TEST_PASSWORD || 'Password123!';
const USER_COUNT = Number(__ENV.USER_COUNT || 50);
const SEED_USERS = Number(__ENV.SEED_USERS || Math.min(USER_COUNT, 20));
const SKIP_REGISTER = (__ENV.SKIP_REGISTER || '').toLowerCase() === '1' || (__ENV.SKIP_REGISTER || '').toLowerCase() === 'true';
const ALLOW_OVERLOAD = (__ENV.ALLOW_OVERLOAD || '').toLowerCase() === '1' || (__ENV.ALLOW_OVERLOAD || '').toLowerCase() === 'true';

function jsonHeaders() {
  return { headers: { 'Content-Type': 'application/json' } };
}

function register(email) {
  const payload = JSON.stringify({ email, password: TEST_PASSWORD });
  return http.post(`${BASE_URL}/register`, payload, jsonHeaders());
}

function login(email) {
  const payload = JSON.stringify({ email, password: TEST_PASSWORD });
  return http.post(`${BASE_URL}/login`, payload, jsonHeaders());
}

function refresh(refreshToken) {
  const payload = JSON.stringify({ refresh_token: refreshToken });
  return http.post(`${BASE_URL}/refresh`, payload, jsonHeaders());
}

function logout(refreshToken) {
  const payload = JSON.stringify({ refresh_token: refreshToken });
  return http.post(`${BASE_URL}/logout`, payload, jsonHeaders());
}

export function setup() {
  // Prépare une liste d'utilisateurs stables par run.
  // Le timestamp évite les collisions entre exécutions.
  const runId = __ENV.RUN_ID || String(Date.now());
  const users = [];
  for (let i = 1; i <= SEED_USERS; i++) {
    users.push(`loadtest+${runId}+${i}@example.com`);
  }

  // Le seeding (register) est volontairement limité car Argon2 est coûteux.
  // Pour un test "grande distribution", on veut surtout mesurer login/refresh/logout.
  if (!SKIP_REGISTER) {
    for (const email of users) {
      const res = register(email);
      check(res, {
        'register status 200/409': (r) => r.status === 200 || r.status === 409,
      });
    }
  }

  return { users };
}

export default function (data) {
  const email = data.users[(__VU - 1) % data.users.length];

  const l = login(email);
  check(l, {
    'login ok (or overload)': (r) => ALLOW_OVERLOAD ? (r.status === 200 || r.status === 408 || r.status === 503) : (r.status === 200),
  });
  if (l.status !== 200) {
    sleep(0.2);
    return;
  }

  const body = l.json();
  const refreshToken = body?.tokens?.refresh_token;
  check(body, {
    'login returns refresh_token': () => typeof refreshToken === 'string' && refreshToken.length > 10,
  });
  if (!refreshToken) {
    sleep(0.2);
    return;
  }

  const rr = refresh(refreshToken);
  check(rr, {
    // Sous surcharge/timeout, on accepte que l'API refuse proprement.
    'refresh ok or refuses cleanly': (r) => r.status === 200 || r.status === 408 || r.status === 503,
  });

  if (rr.status === 200) {
    const rb = rr.json();
    const newRefresh = rb?.refresh_token;
    check(rb, {
      'refresh returns new token': () => typeof newRefresh === 'string' && newRefresh.length > 10,
    });

    const lo = logout(newRefresh);
    check(lo, {
      'logout ok or refuses cleanly': (r) => r.status === 200 || r.status === 204 || r.status === 408 || r.status === 503,
    });
  }

  sleep(0.2);
}
