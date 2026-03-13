# Quanitya Self-Hosted Deployment

## Prerequisites

- Docker and Docker Compose
- OpenSSL and Python 3 (with `cryptography` library — for key generation)

## Quick Start

```bash
cd quanitya_server

# 1. Configure
cp .env.example .env
nano .env   # set POSTGRES_PASSWORD and REDIS_PASSWORD

# 2. Deploy
./scripts/deploy.sh
```

The deploy script generates PowerSync keys, builds the server image, starts all services (Postgres, Redis, PowerSync, Quanitya), and applies migrations.

## Environment Variables

### Required (in `.env`)

| Variable | Description |
|----------|-------------|
| `POSTGRES_PASSWORD` | PostgreSQL password |
| `REDIS_PASSWORD` | Redis password |

PowerSync keys are auto-generated into `.jwk` on first deploy (same format as cloud production).

### Optional: SMTP email

Without SMTP, verification codes are logged to the server console — you can read them directly since you're the admin.

| Variable | Description | Default |
|----------|-------------|---------|
| `SMTP_HOST` | SMTP server hostname | _(disabled)_ |
| `SMTP_PORT` | SMTP port | `587` |
| `SMTP_USERNAME` | SMTP username | |
| `SMTP_PASSWORD` | SMTP password | |
| `SMTP_FROM` | From address | `noreply@<SMTP_HOST>` |
| `SMTP_SSL` | Use SSL | `false` |

### Optional: R2 archival

Needed only if you want old entries (6+ months) archived to Cloudflare R2. Without this, entries stay in Postgres forever.

| Variable | Description |
|----------|-------------|
| `R2_ACCOUNT_ID` | Cloudflare account ID |
| `R2_ACCESS_KEY_ID` | R2 API token access key |
| `R2_SECRET_ACCESS_KEY` | R2 API token secret |
| `R2_BUCKET_NAME` | R2 bucket name (e.g. `quanitya-archives`) |

To set up R2: Cloudflare Dashboard > R2 Object Storage > create a bucket > create an API token with Object Read & Write permissions.

## Connecting the Flutter app

Point the app at your server:

- Serverpod: `http://<your-host>:8080`
- PowerSync: `http://<your-host>:8095`

## Stopping

```bash
docker compose -f docker-compose.prod.yaml down
```

## Production notes

- Put a reverse proxy (nginx, Caddy) in front for SSL
- Change all default passwords
- Back up PostgreSQL regularly (`pg_dump`)
