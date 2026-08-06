---
name: nextjs-rules
description: Next.js App Router architecture rules for both auditing and development. Use when asked to "review this next app", "check architecture", "audit this nextjs project", "does this follow nextjs rules", "review my app router structure", "add a new route", "add a new page", "add a server action", "add a route handler", "implement this feature", or when starting any Next.js development task.
version: 1.0.0
---

# Next.js Architecture Rules

> This skill is the **definitive source** for Next.js App Router architecture rules. Any agent (architect, dev, or otherwise) should load this skill for authoritative rules on the server/client boundary, data access, routing, caching, auth, and design style.

---

## 1. Stack

Expected stack: **Next.js 15+ (App Router) + React 19 + TypeScript + Tailwind CSS v4 + shadcn/ui**

- pnpm (package management)
- [ ] **App Router only** — no `pages/` directory, no `getServerSideProps` / `getStaticProps` / `getInitialProps`
- [ ] Function components only — no legacy class components (except `error.tsx` boundaries, which are function components too)
- [ ] Tailwind v4 syntax used (no `tailwind.config.js` color overrides — use CSS variables)
- [ ] shadcn/ui primitives used for UI — not custom-rolled replacements
- [ ] `next/image` for all images, `next/font` for all fonts — never raw `<img>` or `<link rel="stylesheet">` font tags
- [ ] `next/link` for all internal navigation — never bare `<a href="/...">`

**Key conventions:**
- Path alias `@` → `src/` — all imports use `@/` paths
- All filenames use **kebab-case** — `login-form.tsx`, `user-card.tsx` — except Next.js reserved filenames (`page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`, `not-found.tsx`, `route.ts`, `template.tsx`, `middleware.ts`) and its segment syntax (`[id]`, `[...slug]`, `(group)`, `@slot`)
- Missing shadcn primitive → `pnpm dlx shadcn@latest add <component>` (installs into `src/components/ui/`)

---

## 2. Structure

```
src/
  app/                          # routing ONLY — no components defined here
    layout.tsx                  # root layout: fonts, metadataBase, providers
    page.tsx
    (marketing)/                # route groups for shared layouts
    dashboard/
      page.tsx
      loading.tsx
      error.tsx
    api/
      webhooks/stripe/route.ts  # route handlers — see § 5
  components/
    ui/                         # shadcn components only, never edited manually
    {feature}/                  # feature-specific components
    common/                     # cross-cutting utility components
  server/
    {domain}/
      queries.ts                # read path  — 'server-only'
      actions.ts                # write path — 'use server'
      schema.ts                 # zod input schemas
      index.ts                  # barrel
  lib/
    utils.ts                    # cn(), shared helpers
    session.ts                  # getSession() — 'server-only'
    db.ts                       # db client — 'server-only'
  types.ts
  middleware.ts
```

- `src/app/` — **routing only**. Reserved files, route groups, and segment folders. Never define a reusable component here; a `page.tsx` composes components imported from `@/components/`
- `src/server/{domain}/` — all data access for a domain: `queries.ts` + `actions.ts` + `schema.ts` + `index.ts`
- `src/lib/` — shared utilities only; anything touching the DB, secrets, or cookies starts with `import 'server-only'`
- `src/components/ui/` — shadcn components only, never edited manually

#### Naming Rules
- [ ] All non-reserved filenames must be **kebab-case**
- [ ] Each feature folder and each `server/{domain}/` folder must have an `index.ts` barrel export
- [ ] Route groups `(name)` used to share layouts without adding URL segments — not as a dumping ground

#### Import Rules
- [ ] All imports use `@/` path aliases — no relative `../../` imports crossing feature boundaries
- [ ] Missing shadcn primitive → add via `pnpm dlx shadcn@latest add <component>` (installs into `ui/`)

---

## 3. Server / Client Boundary

This is the rule that matters most. Get it wrong and everything else leaks.

- [ ] **Server Components by default.** `'use client'` is opt-in, never the default
- [ ] `'use client'` only when the component genuinely needs: `useState` / `useReducer` / `useEffect`, event handlers, browser APIs, or a client-only library
- [ ] **Push `'use client'` to the leaves.** Never put it on `layout.tsx` or `page.tsx` — extract the interactive part into `@/components/{feature}/xxx.tsx` and mark that
- [ ] Client Components are **never `async`** — no top-level `await` in a `'use client'` file
- [ ] Server data reaches Client Components as **serializable props**, or as `children` passed from a Server Component
- [ ] `import 'server-only'` at the top of every module that touches the DB, secrets, cookies, or private APIs — this makes a bad import a build error instead of a leak
- [ ] Secrets live in non-`NEXT_PUBLIC_` env vars and are read **only** in server modules. Any `NEXT_PUBLIC_` variable is public — treat it as printed on the homepage

**Violations to flag:**
- `'use client'` at the top of a `layout.tsx` or `page.tsx`
- An `async` function component in a `'use client'` file
- A Client Component importing from `@/server/**` or `@/lib/db`
- A server module missing `import 'server-only'`
- Non-serializable props (functions other than Server Actions, class instances, `Date` where a string is expected) crossing the boundary

---

## 4. Data Access

- [ ] **Reads happen in Server Components**, by calling a function from `@/server/{domain}/queries.ts`. Never `useEffect` + `fetch` to load initial data
- [ ] **Writes happen in Server Actions** in `@/server/{domain}/actions.ts`, file marked `'use server'`
- [ ] Components never talk to the DB or a third-party API directly — always through `@/server/{domain}/`
- [ ] Every query function that may be called more than once per render is wrapped in `React.cache()` so `generateMetadata` and the page share one fetch
- [ ] **No request waterfalls** — start independent promises first, then `await Promise.all([...])`. Sequential `await`s for unrelated data are a violation
- [ ] Slow, non-critical sub-trees are wrapped in `<Suspense>` and stream, rather than blocking the whole page

#### Server Actions

- [ ] **Every Server Action re-checks auth itself.** A Server Action is a public HTTP endpoint — rendering it behind a guarded page proves nothing
- [ ] Input validated with a zod schema from `schema.ts` before anything else — never trust `FormData`
- [ ] Ends with `revalidatePath()` / `revalidateTag()` for the affected data, then `redirect()` if the route should change
- [ ] Returns a plain serializable result (`{ error }` / `{ data }`) — never throws raw DB errors at the client
- [ ] Forms use `useActionState` for result state and `useFormStatus` for pending state — no manual `isSubmitting` `useState`
- [ ] Not used for reads. If you're calling an action to fetch data, it should have been a Server Component

**`server/{domain}/index.ts` pattern:**
```ts
export * from './queries'
export * from './actions'
export * from './schema'
```

#### Adding a domain (expected pattern)
1. Types → `src/types.ts`
2. `src/server/{domain}/schema.ts` → `queries.ts` → `actions.ts` → `index.ts`
3. Components → `src/components/{domain}/`
4. Route → `src/app/{domain}/page.tsx` (+ `loading.tsx`, `error.tsx`)
5. Metadata → `export const metadata` or `generateMetadata` in that `page.tsx`

---

## 5. Route Handlers

`app/api/**/route.ts` is the **exception**, not the default. Most apps need very few.

- [ ] A route handler is justified only for: **webhooks**, third-party OAuth callbacks, non-HTML responses (files, streams, images, RSS), or a public API consumed by something that isn't this app
- [ ] **Never create a route handler for your own UI to fetch from** — that's a Server Component (read) or a Server Action (write)
- [ ] Exports named HTTP verbs (`GET`, `POST`, …) — never a default export
- [ ] Validates input with zod; returns `NextResponse.json()` with an explicit status
- [ ] Checks auth itself via `getSession()` — same rule as Server Actions
- [ ] Never returns internal error messages or stack traces to the caller
- [ ] Webhook handlers verify the signature before parsing the body

---

## 6. Middleware

- [ ] `src/middleware.ts` does **cheap edge-level work only**: session-cookie presence checks, redirects, locale, rewrites
- [ ] **Middleware is not an authorization boundary.** It is a redirect optimization. Real authorization happens in the Server Component / Server Action / Route Handler via `getSession()`
- [ ] No database calls, no secret-dependent crypto, no heavy work — it runs on every matched request
- [ ] `export const config = { matcher: [...] }` must exclude static assets (`_next/static`, `_next/image`, `favicon.ico`, public files)

---

## 7. Auth & Sessions

- [ ] Session lives in an **`httpOnly`, `Secure`, `SameSite=Lax` cookie**. Never `localStorage`, never `sessionStorage`, never a client-readable JWT
- [ ] `src/lib/session.ts` starts with `import 'server-only'` and exports `getSession()`, wrapped in `React.cache()`
- [ ] `cookies()`, `headers()`, `draftMode()`, `params`, and `searchParams` are **async in Next 15** — always `await` them
- [ ] Login / logout are Server Actions that set and delete the cookie — not route handlers
- [ ] Protected pages call `getSession()` and `redirect()` when absent; they do not rely on middleware having done it
- [ ] Auth checks live next to the data access, so every caller gets them

---

## 8. Caching & Rendering

Next.js caching is implicit. **Make the intent explicit** so a reader knows whether a page is static or dynamic without reasoning about it.

- [ ] Every route that is not plainly static declares its intent at the segment: `export const revalidate = N`, `export const dynamic = 'force-dynamic'`, or `export const dynamic = 'force-static'`
- [ ] `fetch` calls state their caching explicitly: `{ next: { revalidate: N, tags: ['...'] } }` or `{ cache: 'no-store' }`
- [ ] Data is tagged (`tags`) so mutations can `revalidateTag()` precisely — prefer tags over blanket `revalidatePath('/')`
- [ ] **Every mutation revalidates what it changed.** Stale UI after a Server Action is a violation, not a refresh problem
- [ ] Dynamic segments with an enumerable set of values export `generateStaticParams()`
- [ ] Every route that awaits data has a `loading.tsx`; slower sub-trees get their own `<Suspense fallback>` so the shell streams first
- [ ] Every route segment with data has an `error.tsx` — a Client Component accepting `{ error, reset }`
- [ ] Missing resources call `notFound()`; the segment provides `not-found.tsx`
- [ ] Unstable, per-request values (`Date.now()`, `Math.random()`, `headers()`) never appear in a route intended to be static

---

## 9. Metadata & SEO

- [ ] Root `layout.tsx` sets `metadataBase`, a `title.template`, and a default `description`
- [ ] Every `page.tsx` exports `metadata` (static) or `generateMetadata` (dynamic) — a page with no metadata is a violation
- [ ] `generateMetadata` reuses the **same `React.cache()`-wrapped query** as the page, so the data is fetched once
- [ ] `app/sitemap.ts` and `app/robots.ts` exist for any public-facing site
- [ ] Open Graph images via `app/opengraph-image.tsx` (or explicit `openGraph.images`) — not hand-written `<meta>` tags
- [ ] Canonical URLs set via `alternates.canonical` on routes reachable at more than one path
- [ ] No manual `<title>` / `<meta>` in JSX — use the Metadata API

---

## 10. Components

- [ ] **One component per file** — never define multiple components in a single file. Sub-components (tabs, sections, dialogs) must be extracted to `src/components/{feature}/`. Trivial one-liner wrappers used only once may stay inline
- [ ] Proper TypeScript types for all props — no `any`
- [ ] `cn()` used for all className merging — never string concatenation
- [ ] **Forms:** always use `FieldGroup`, `FieldLabel`, `FieldDescription` from `@/components/ui/field` — never use `Label` directly in forms
- [ ] Complex client logic extracted to custom hooks
- [ ] Utility functions added to `src/lib/utils.ts`, not inline
- [ ] Proper `key` props on all lists
- [ ] Heavy client-only components loaded via `next/dynamic`
- [ ] All async operations have loading and error states

#### Body Ordering

**Server Components** — no hooks, no effects:

1. **Declarations** — `await` params/session, kick off queries, then derived values
2. **Render helpers** — `const renderXxx = () => <JSX />` for distinct sections
3. **Compose** — `const renderMain = () => { ... }` handles empty/branching cases
4. **Return** — `return renderMain()`; no early returns except `notFound()` / `redirect()`

**Client Components** — same five-step order as `react-rules`:

1. **Declarations** — all `const` together: hooks (`useParams`, `useState`, `useActionState`), then derived values
2. **Effects** — `useEffect` and other side-effect hooks
3. **Render helpers**
4. **Compose**
5. **Return**

```tsx
// ✅ Server Component
// 1. declarations
const { id } = await params
const session = await getSession()
const [item, comments] = await Promise.all([getItem(id), getComments(id)])
const isEmpty = !comments.length

// 2. render helpers
const renderHeader = () => <ItemHeader item={item} />
const renderComments = () => <CommentList comments={comments} />

// 3. compose
const renderMain = () => {
  if (isEmpty) return <EmptyState />
  return renderComments()
}

// 4. return
return <div>{renderHeader()}{renderMain()}</div>
```

**Violations to flag:**
- Multiple exported components in a single file
- Early returns or nested ternaries in JSX
- Utility functions defined inline in a component
- Components defined inside `src/app/`
- `useEffect` used to fetch data that a Server Component could have loaded

---

## 11. Design Style

- [ ] **The project must have a `DESIGN.md` file** at the root — if missing, copy the default one bundled with this skill (`nextjs-rules/DESIGN.md`) to the project root and inform the user that a default design system has been applied
- [ ] **Read `DESIGN.md`** before building any UI — components and pages must follow it
- [ ] Flag any UI patterns that visibly contradict the documented design rules (e.g. wrong border-radius, wrong button size, wrong color usage, wrong typography)

When a `DESIGN.md` is present, read it before building any UI and follow it strictly:
- Match the spacing, color, corner style, and component patterns defined there
- Use `cn()` for all className merging
- Prefer shadcn primitives over custom-built UI elements

---

## Auditing a project

These rules are the source of truth for auditing as well. When reviewing an existing project against them, use the **`nextjs-architect`** skill — it defines the review process and report format and audits against the rules above.
