# PROBE Platform Architecture (Foundation)

This document defines the **initial scalable architecture** for PROBE.

Scope of this stage:
- Project structure
- Environment variable strategy
- Supabase client setup (browser/server/admin separation)
- Shared types and config layer

Out of scope:
- UI pages
- Business logic
- Domain implementation

## 1) High-level architecture

PROBE follows a layered approach:

- `app` layer: Next.js App Router entrypoints (kept empty for now)
- `feature` layer: business capabilities grouped by domain (future)
- `service` layer: reusable infrastructure services (future)
- `lib` layer: technical integrations and low-level helpers
- `config` layer: runtime configuration and constants
- `types` layer: global and generated types

This separation keeps domain logic independent from framework and transport details.

## 2) Directory structure

```txt
src/
  app/                    # App Router entrypoints (foundation only)
  config/
    app.ts                # App-level metadata
    env.ts                # Runtime env parsing + validation
    index.ts              # Config exports
  features/               # Future vertical slices (payments, ledger, etc.)
  hooks/                  # Shared React hooks (future)
  lib/
    api/                  # API client helpers (future)
    supabase/
      admin.ts            # Service-role client (server-only)
      client.ts           # Browser client
      server.ts           # Request-scoped server client
      index.ts            # Supabase exports
    utils/                # Utility helpers (future)
  modules/                # Future shared domain modules
  services/               # Future infrastructure services
  store/                  # Future state management
  styles/                 # Global style system and tokens (future)
  types/
    database.ts           # Supabase Database type contract
    global.d.ts           # Global TS and ProcessEnv declarations
    index.ts              # Type exports

docs/
  architecture.md         # This file

.env.example              # Required and optional environment variables
```

## 3) Environment variable system

Environment variables are centralized in `src/config/env.ts`.

Principles:
- Required keys fail fast at startup.
- Optional keys stay explicit and typed.
- No direct `process.env.*` usage outside config.

Required:
- `NEXT_PUBLIC_APP_URL`
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`

Optional:
- `SUPABASE_SERVICE_ROLE_KEY` (needed only for privileged server flows)
- `SENTRY_DSN`

## 4) Supabase client separation

Three clients are defined under `src/lib/supabase`:

1. `client.ts` (browser)
   - Uses anon key
   - For authenticated end-user interactions in browser runtime

2. `server.ts` (request server)
   - Uses anon key with cookie bridge
   - For App Router server components/actions/route handlers
   - Preserves session using request cookies

3. `admin.ts` (service role)
   - Uses service role key
   - For trusted backend operations only
   - Must never be imported into browser code

This split prevents accidental privilege escalation and keeps auth/session handling explicit.

## 5) Global types strategy

- `src/types/global.d.ts` defines global utility types and typed `ProcessEnv` keys.
- `src/types/database.ts` is the stable import path for generated Supabase types.

When schema is ready, replace `database.ts` with generated output to propagate typing across repositories and services.

## 6) Config layer

- `src/config/app.ts` stores static application metadata.
- `src/config/env.ts` stores runtime environment mapping.
- `src/config/index.ts` is the single import barrel.

Usage guideline:
- Import from `@/config` everywhere (`env`, `appConfig`) to enforce consistency.

## 7) Next implementation steps (future)

After foundation approval:
1. Add base App Router shell (layout + error/not-found boundaries).
2. Add auth module boundaries (session, RBAC, tenant context).
3. Add finance domain modules (accounts, ledgers, transactions).
4. Add observability and audit logging.
5. Add CI typecheck/lint/test pipelines.
