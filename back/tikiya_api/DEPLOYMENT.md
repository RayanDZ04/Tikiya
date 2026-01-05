# Déploiement (objectif: ultra-stable)

Ce document couvre les réglages indispensables pour rendre l’API robuste sous charge et éviter les crashs par épuisement de ressources.

## 1) Variables d’environnement (recommandées)

Obligatoires:
- `DATABASE_URL`
- `JWT_SECRET`

Recommandées:
- `PORT` (défaut: 8080)
- `DATABASE_POOL_MAX` (défaut: 20)
- `JWT_ISSUER` (défaut: `tikiya-api`)
- `JWT_AUDIENCE` (défaut: `tikiya-clients`)

Résilience HTTP (ajoutées):
- `HTTP_REQUEST_TIMEOUT_SECS` (défaut: 30)
- `HTTP_CONCURRENCY_LIMIT` (défaut: 1024)
- `HTTP_MAX_BODY_BYTES` (défaut: 1048576)

Notes:
- `HTTP_CONCURRENCY_LIMIT` doit être ajusté selon CPU/RAM et la capacité Postgres.
- Si tu as un reverse-proxy (Nginx/Traefik), garde aussi des limites côté proxy.

## 2) Réglages OS (Linux)

Ces réglages évitent que le process tombe en panne faute de fichiers/sockets.

- Augmenter les limites de fichiers ouverts:
  - `LimitNOFILE=1048576` (systemd)
  - ou `ulimit -n 1048576` (temporaire)

- Vérifier les limites:
  - `cat /proc/sys/fs/file-max`
  - `sysctl net.core.somaxconn`

## 3) Exemple systemd (recommandé)

Créer un service (exemple) et adapter les chemins:

```ini
[Unit]
Description=Tikiya API
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/tikiya_api
EnvironmentFile=/opt/tikiya_api/.env
ExecStart=/opt/tikiya_api/tikiya_api
Restart=always
RestartSec=2

# Robustesse
LimitNOFILE=1048576

# Sécurité basique
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/tikiya_api

[Install]
WantedBy=multi-user.target
```

## 4) Reverse proxy (conseillé)

Pourquoi:
- Terminaison TLS
- limites de taille/timeout côté edge
- protection contre certains abus

À prévoir côté proxy:
- timeout upstream (un peu > `HTTP_REQUEST_TIMEOUT_SECS`)
- limite de taille request body (doit matcher `HTTP_MAX_BODY_BYTES`)
- keep-alive / compression si utile

## 5) Base de données (Postgres)

- Ajuster `DATABASE_POOL_MAX` selon Postgres.
- Surveiller:
  - connexions actives
  - latence des requêtes
  - verrous

## 6) Migrations

Important:
- Une migration `0006_schema_guard.sql` existe pour échouer immédiatement si le schéma `users` ne correspond pas au code (ex: `users.id` doit être UUID).
- Ne pas modifier des migrations déjà appliquées en prod (sinon checksum SQLx casse).

## 7) Tests de charge (à faire ensuite)

Outils possibles:
- `k6`
- `vegeta`

Scénarios minimum:
- login -> refresh -> logout
- 2–10 minutes de charge constante
- montée progressive jusqu’au seuil de saturation

But:
- trouver le bon `HTTP_CONCURRENCY_LIMIT`
- valider que le serveur refuse proprement (timeouts/429/503) au lieu de crash
