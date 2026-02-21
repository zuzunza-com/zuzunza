# zuzunza (Parent Repository)

This is the parent repository for the Zuzunza platform.

## Repository Role
- Acts as the top-level parent (`zuzunza`) for all critical platform repositories.
- Manages submodule pinning for reproducible deployments and audits.
- Default policy in this setup: **all listed sub-repositories are private**.

## Submodule Topology

```text
zuzunza (parent)
└── platform/
    ├── zuzunza-waterscape
    ├── wscp-deploy-core
    ├── wscp-frontend
    ├── wscp-memphis-core-serven
    ├── wscp-memphis-discord-bot
    ├── wscp-library
    ├── wscp-middleware
    ├── wscp-servgate
    └── wscp-gateware
```

## Quick Start

```bash
git clone https://github.com/zuzunza-com/zuzunza.git
cd zuzunza
git submodule sync --recursive
git submodule update --init --recursive
```

## Visibility Governance

Current policy target:
- Core/deploy/frontend/serven: private
- External publishing repos may be public later, but currently private-first operation is applied.

See `docs/repository-visibility-policy.md`.
