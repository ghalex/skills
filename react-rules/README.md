# react-rules

Claude Code skill that defines React architecture rules for both development and auditing. Loaded by dev agents when implementing features and by review agents when auditing code.

## Install

```bash
npx skills add zenve-ai/zenve-registry/skills --skill react-rules
```

## Usage

**When developing:**

> "add a new page"
> "add a new component"
> "add a new store domain"
> "implement this feature"

**When auditing:**

> "review my components"
> "check architecture"
> "audit this react project"
> "does this follow the react rules"
> "review my frontend structure"

## What it covers

**Stack** — React 19 + Vite + TypeScript + Tailwind CSS v4 + shadcn/ui + Redux Toolkit + React Router, with pnpm

**Structure** — `src/pages/`, `src/store/{domain}/`, `src/lib/`, `src/components/` layout, kebab-case filenames, barrel `index.ts` exports, `@/` path aliases

**Components** — one component per file, TypeScript props, `cn()` merging, body ordering (declarations → effects → render helpers → compose → return), form field rules, violations to flag

**Store** — RTK Query for server data, Redux slices for client state, `useAppDispatch` / `useAppSelector` only, domain folder pattern, route guards

**Design Style** — reads `CLAUDE.md` design section; falls back to shadcn/ui defaults

## Architecture Review output (architect agents only)

```
## Architecture Review

### ✅ Passing
- Components correctly use one-component-per-file rule
- ...

### ❌ Violations
#### src/pages/dashboard.tsx
- **Rule:** No components defined in pages
- **Found:** DashboardCard component defined inline in the page file
- **Fix:** Extract to src/components/dashboard/dashboard-card.tsx and import it

### Summary
2 violations found in 1 file.
```
