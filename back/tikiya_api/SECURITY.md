# Sécurité — Tikiya! API

Ce document décrit les protections en place et la procédure de réponse à incident.
Il est destiné à l'équipe technique.

## Protections en place

- **Mots de passe** : hachés en Argon2id, jamais stockés en clair. Politique de
  complexité à l'inscription/changement (≥ 8 caractères, au moins une lettre et
  un chiffre). Verrouillage du compte 15 min après plusieurs échecs.
- **Sessions** : JWT d'accès courts + refresh tokens opaques, rotatifs et
  révocables. Un changement de mot de passe révoque toutes les sessions.
- **Vérification d'email** : connexion bloquée tant que l'email n'est pas
  vérifié (code OTP à usage unique, haché en base, expirant).
- **Limitation de débit** : limiteur distribué (Redis) partagé entre répliques,
  plus un limiteur strict sur les endpoints d'authentification.
- **Paiement** : montant recalculé côté serveur, anti-survente (`FOR UPDATE`),
  signature de webhook HMAC vérifiée en temps constant, anti-rejeu, clé HMAC
  distincte du secret JWT.
- **Uploads** : type validé par les octets réels (pas l'en-tête client), quota
  par utilisateur, noms de fichiers générés (pas de traversée de chemin).
- **Contrôle d'accès** : chaque ressource est filtrée par propriétaire ; rôle
  admin vérifié en base à chaque requête.
- **Journal d'audit** : actions sensibles (mot de passe, email, suppression de
  compte, suppression d'événement) tracées dans `audit_log`.
- **RGPD** : export (`GET /me/export`) et suppression définitive (`DELETE /me`)
  des données personnelles, protégés par mot de passe.
- **CI** : `cargo audit` (failles connues des dépendances) + `clippy` en CI,
  plus un scan hebdomadaire programmé.
- **Infra prod** : base non exposée au public, secrets obligatoires (le
  déploiement échoue sans `DB_PASSWORD`), TLS via Caddy, sauvegardes DB
  quotidiennes.

## Signaler une faille

Contact sécurité : **security@tikiya.net** (à créer). Ne pas divulguer
publiquement une faille avant correction.

## Procédure de réponse à incident

1. **Détecter & confirmer** — identifier la nature (fuite de données, compte
   compromis, indisponibilité) et l'ampleur via les logs et `audit_log`.
2. **Contenir** — isoler le composant touché ; si compromission de secret,
   passer directement à l'étape 4.
3. **Éradiquer** — corriger la cause (patch, blocage d'IP, désactivation de
   compte).
4. **Rotation des secrets d'urgence** — régénérer et redéployer : `JWT_SECRET`,
   `DB_PASSWORD`, clés MinIO, clé API Chargily, clé Resend. La rotation du
   `JWT_SECRET` invalide toutes les sessions (déconnexion générale volontaire).
5. **Restaurer** — si perte/corruption de données, restaurer depuis la dernière
   sauvegarde saine (`db_backup`) et vérifier l'intégrité.
6. **Notifier** — si des données personnelles sont concernées, informer les
   utilisateurs et l'autorité compétente dans les délais légaux (RGPD : 72 h).
7. **Post-mortem** — documenter la cause racine et les actions correctives pour
   éviter la récurrence.

## Éléments encore à la charge de l'exploitant (hors code)

- Gestionnaire de secrets (coffre) au lieu de fichiers `.env`.
- Pare-feu / groupes de sécurité au niveau du cloud.
- Copie des sauvegardes DB hors de la machine hôte.
- Agrégation centralisée des logs + alertes.
- Test d'intrusion externe par un tiers avant montée en charge majeure.
