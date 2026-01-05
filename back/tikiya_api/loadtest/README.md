# Load tests (k6)

Objectif : valider que l’API tient la charge en **refusant proprement** (503/408) au lieu de crasher.

## Prérequis

- Serveur lancé (local ou staging)
- Une base Postgres accessible et migrations appliquées
- `k6` installé

Installation k6 (Ubuntu/Debian) :
- `sudo apt-get update && sudo apt-get install -y k6`

## Variables d’environnement

- `BASE_URL` (défaut: `http://127.0.0.1:8080`)
- `TEST_PASSWORD` (défaut: `Password123!`)
- `USER_COUNT` (défaut: `50`) nombre d’utilisateurs distincts à créer/utiliser

Options de charge :
- `VUS` (défaut selon script)
- `DURATION` (défaut selon script)

## 1) Smoke test

- `BASE_URL=http://127.0.0.1:8080 k6 run smoke.js`

Vérifie:
- `/health` retourne 200
- `/ready` retourne 200

## 2) Auth cycle (login → refresh → logout)

Ce test:
- crée (ou réutilise) `USER_COUNT` utilisateurs via `/register`
- exécute en boucle: `/login` → `/refresh` → `/logout`
- vérifie que les réponses sont cohérentes (tokens présents, statuts)

Exemple (charge modérée):
- `BASE_URL=http://127.0.0.1:8080 USER_COUNT=100 VUS=50 DURATION=2m k6 run auth_cycle.js`

## 3) Test “surcharge” contrôlée

But : vérifier qu’en saturation l’API répond **503 Server Busy** / **408 Timeout** au lieu de crasher.

Procédure (local):
1. Lancer l’API avec une limite volontairement basse:
   - `HTTP_CONCURRENCY_LIMIT=32 HTTP_REQUEST_TIMEOUT_SECS=10 ...`
2. Lancer un test agressif:
   - `BASE_URL=http://127.0.0.1:8080 USER_COUNT=200 VUS=200 DURATION=2m k6 run auth_cycle.js`

À observer:
- une partie des requêtes peut être rejetée en 503/408 (c’est normal)
- le process ne doit pas tomber
- la DB ne doit pas être saturée durablement

## Tips de validation “production-grade”

- Surveille:
  - CPU/RAM du process
  - connexions Postgres actives
  - latence p95/p99
  - taux de 5xx
- Ajuste en priorité:
  - `HTTP_CONCURRENCY_LIMIT`
  - `DATABASE_POOL_MAX`

