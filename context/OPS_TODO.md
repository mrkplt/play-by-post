# Ops / Infrastructure Todo List

Personal backlog of operational concerns for this project. This is a toy project, so
most of these are low urgency — nice-to-haves rather than requirements. The two areas
worth prioritizing first are **network security** and **service restoration**
(backups + rebuild docs); everything else is aspirational.

## Security (priority)
- Intrusion detection
- Firewall hardening

## Backups (priority — service restoration)
- Coolify instance (config/state)
- Production database (SQLite, mounted volume)
- Reverse proxy / Traefik router configuration (Coolify-managed)
- Physical/network router configuration
- Pi server rebuild documentation (so the host itself can be rebuilt from scratch)

## Telemetry
- App-layer telemetry: error tracking, performance monitoring (Rails)
- Infrastructure-layer telemetry: container/host performance monitoring

## Monitoring / alerting
- Alerting/on-call routing (someone gets notified when errors spike or jobs back up)
- Backup restore testing (periodically verify a snapshot actually restores)
- Secrets backup (Rails master key, R2 credentials, Resend API key)
- Email deliverability monitoring (Resend bounce/complaint rates)
- Abuse/rate-limiting on public-ish endpoints (magic-link sign-in, inbound email webhook)
- Disk space alerting (SQLite volume, R2 usage)

## Issue / product tracking
- Bug tracking / error tracking
- Feature tracking / product management
