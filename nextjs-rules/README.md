# nextjs-rules

Claude Code skill that defines Next.js App Router architecture rules for both development and auditing. Loaded by dev agents when implementing features and by review agents when auditing code.

## Install

```bash
npx skills add ghalex/skills --skill nextjs-rules
```

## Usage

**When developing:**

> "add a new route"
> "add a new page"
> "add a server action"
> "add a route handler"
> "implement this feature"

**When auditing:**

> "review this next app"
> "check architecture"
> "audit this nextjs project"
> "does this follow the nextjs rules"
> "review my app router structure"

## What it covers

**Stack** — Next.js 15+ App Router + React 19 + TypeScript + Tailwind CSS v4 + shadcn/ui, with pnpm. No `pages/`, no `getServerSideProps`

**Structure** — `src/app/` for routing only, `src/server/{domain}/`, `src/lib/`, `src/components/` layout, kebab-case filenames (Next reserved names excepted), barrel `index.ts` exports, `@/` path aliases

**Server / Client boundary** — Server Components by default, `'use client'` pushed to the leaves, no `async` client components, `import 'server-only'` on every server module, serializable props only

**Data access** — reads in Server Components via `server/{domain}/queries.ts`, writes via Server Actions in `actions.ts`, zod validation, `React.cache()` dedup, `Promise.all` instead of waterfalls, auth re-checked inside every action

**Route handlers** — reserved for webhooks, OAuth callbacks, non-HTML responses, and external consumers — never for your own UI to fetch from

**Middleware** — cheap edge checks and redirects only; explicitly *not* an authorization boundary

**Auth & sessions** — `httpOnly` cookies, never `localStorage`; `getSession()` in `lib/session.ts` wrapped in `React.cache()`; `await cookies()` / `await params` in Next 15

**Caching & rendering** — explicit `revalidate` / `dynamic` per segment, tagged fetches, mandatory revalidation after mutations, `generateStaticParams`, `loading.tsx` + `<Suspense>` streaming, `error.tsx` / `not-found.tsx`

**Metadata & SEO** — `metadata` or `generateMetadata` on every page, `metadataBase` + title template in the root layout, `sitemap.ts`, `robots.ts`, `opengraph-image.tsx`

**Components** — one component per file, TypeScript props, `cn()` merging, body ordering for both Server and Client Components, form field rules, violations to flag

**Design Style** — requires a `DESIGN.md` at the project root; copies the bundled default when missing

## Relationship to the other skills

| Skill | Role |
|---|---|
| `nextjs-rules` | The rules themselves — loaded during development *and* auditing |
| `nextjs-architect` | The review process and report format; loads these rules as its checklist |
| `react-rules` | The SPA equivalent (Vite + Redux Toolkit + React Router) for client-rendered apps |

## Architecture Review output (architect agents only)

```
## Architecture Review

### ✅ Passing
- Server Components used by default; 'use client' only on leaf components
- ...

### ❌ Violations
#### src/app/dashboard/page.tsx
- **Rule:** No 'use client' on page.tsx — push the boundary to the leaves
- **Found:** Whole page marked 'use client' to support a single dropdown
- **Fix:** Extract the dropdown to src/components/dashboard/filter-dropdown.tsx, mark that 'use client', and keep the page a Server Component

### Summary
2 violations found in 1 file.
```
