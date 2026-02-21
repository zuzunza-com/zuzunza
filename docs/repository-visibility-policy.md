# Repository Visibility Policy

Updated: 2026-02-21

## Parent-Child Rule
- `zuzunza-com/zuzunza` must remain the top-level parent repository.
- Critical repositories must be connected as submodules under `platform/`.

## Classification

### Private (current enforced)
- zuzunza
- zuzunza-waterscape
- wscp-deploy-core
- wscp-frontend
- wscp-memphis-core-serven
- wscp-memphis-discord-bot
- wscp-library
- wscp-middleware
- wscp-servgate
- wscp-gateware

### Public (allowed in principle, not enabled now)
- external deploy helpers
- external API docs examples
- non-sensitive SDK sample repositories

## Staging Rules
- Private staging: include all source, infra, deployment, and internal docs.
- Public staging: exclude all secrets, internal infra scripts, private endpoints, and internal runbooks.
- `.env` and secret files must never be committed.
