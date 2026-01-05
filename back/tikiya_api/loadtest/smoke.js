import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 1,
  duration: '10s',
};

const BASE_URL = __ENV.BASE_URL || 'http://127.0.0.1:8080';

export default function () {
  const h = http.get(`${BASE_URL}/health`);
  check(h, {
    'health 200': (r) => r.status === 200,
  });

  const r = http.get(`${BASE_URL}/ready`);
  check(r, {
    'ready 200': (res) => res.status === 200,
  });

  sleep(1);
}
