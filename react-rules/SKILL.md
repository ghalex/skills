---
name: react-rules
description: React architecture rules for both auditing and development. Use when asked to "review components", "check architecture", "audit this react project", "does this follow react rules", "review my frontend structure", "add a new page", "add a new component", "add a new store domain", "implement this feature", or when starting any React development task.
version: 1.0.0
---

# React Architecture Rules

> This skill is the **definitive source** for React architecture rules. Any agent (architect, dev, or otherwise) should load this skill for authoritative rules on components, store, structure, and design style.

---

## 1. Stack

Expected stack: **React 19 + Vite + TypeScript + Tailwind CSS v4 + shadcn/ui + Redux Toolkit + React Router**

- pnpm (package management)
- [ ] No legacy class components — function components only
- [ ] Tailwind v4 syntax used (no `tailwind.config.js` color overrides — use CSS variables)
- [ ] shadcn/ui primitives used for UI — not custom-rolled replacements

**Key conventions:**
- Path alias `@` → `src/` — all imports use `@/` paths
- All filenames use **kebab-case** — no exceptions: `my-component.tsx`, `login-form.tsx`
- Missing shadcn primitive → `pnpm dlx shadcn@latest add <component>` (installs into `src/components/ui/`)

---

## 2. Structure

- `src/pages/` — one file per route; no components defined here
- `src/store/{domain}/` — `slice.ts` + `api.ts` + `index.ts` per domain
- `src/lib/` — shared utilities only (`api.ts`, `token.ts`, `utils.ts`)
- `src/components/auth/` — `PrivateRoute` / `PublicRoute` guards only
- `src/components/ui/` — shadcn components only, never edited manually
- `src/components/{feature}/` — feature-specific components
- `src/components/common/` — cross-cutting utility components
- Path alias `@` → `src/` — all imports use `@/` paths

#### Naming Rules
- [ ] All filenames must be **kebab-case**: `my-component.tsx`, `private-route.tsx`, `login-form.tsx`
- [ ] Each feature folder must have an `index.ts` barrel export

#### Import Rules
- [ ] All imports use `@/` path aliases — no relative `../../` imports crossing feature boundaries
- [ ] Missing shadcn primitive → add via `pnpm dlx shadcn@latest add <component>` (installs into `ui/`)

---

## 3. Components

- [ ] **One component per file** — never define multiple components in a single file. Sub-components (tabs, sections, dialogs) must be extracted to `src/components/{feature}/`. Trivial one-liner wrappers used only once may stay inline.
- [ ] Proper TypeScript types for all props — no `any`
- [ ] `cn()` used for all className merging — never string concatenation
- [ ] **Forms:** always use `FieldGroup`, `FieldLabel`, `FieldDescription` from `@/components/ui/field` — never use `Label` directly in forms
- [ ] Complex logic extracted to custom hooks
- [ ] Utility functions added to `src/lib/utils.ts`, not inline
- [ ] `React.memo` used for expensive components
- [ ] Proper `key` props on all lists
- [ ] Heavy components lazy-loaded where appropriate
- [ ] All async operations have loading and error states

#### Body Ordering

Every component must follow this order — no interleaving:

1. **Declarations** — all `const` together: hooks (`useParams`, `useState`, `useAppSelector`, RTK Query), then derived values computed from them
2. **Effects** — `useEffect` and other side-effect hooks
3. **Render helpers** — `const renderXxx = () => <JSX />` arrow functions for distinct sections
4. **Compose** — `const renderMain = () => { ... }` handles loading/error/empty branching
5. **Return** — `return renderMain()` or compose with render helpers; no early returns, no nested ternaries

```tsx
// ✅ Correct
// 1. declarations
const { id } = useParams()
const { data, isLoading, error } = useGetItemQuery(id)
const isEmpty = !data?.length

// 2. effects
useEffect(() => { ... }, [])

// 3. render helpers
const renderLoading = () => <LoadingSpinner />
const renderError = () => <ErrorMessage error={error} />
const renderContent = () => <MainContent data={data} />

// 4. compose
const renderMain = () => {
  if (isLoading) return renderLoading()
  if (error) return renderError()
  if (isEmpty) return null
  return renderContent()
}

// 5. return
return <div>{renderMain()}</div>
```

**Violations to flag:**
- Multiple exported components in a single file
- Early returns or nested ternaries in JSX
- Utility functions defined inline in a component
- `useDispatch` / `useSelector` used directly (must use `useAppDispatch` / `useAppSelector`)

---

## 4. Store

- [ ] Always use `useAppDispatch` / `useAppSelector` — never plain `useDispatch` / `useSelector`
- [ ] **Server data** fetched via RTK Query in `api.ts` — never use `useState` for data fetched from an API
- [ ] **Client-only state** managed via Redux slice in `slice.ts`
- [ ] Each domain folder has: `slice.ts` + `api.ts` + `index.ts`
- [ ] All domain stores registered in `src/store/index.ts`
- [ ] All protected routes wrapped with `<PrivateRoute>`, public routes with `<PublicRoute>`
- [ ] Routes defined in `src/routes.tsx` only

**`store/{domain}/index.ts` pattern:**
```ts
export * from './slice'
export * from './api'
```

#### Adding a domain (expected pattern)
1. Types → `src/types.ts`
2. `src/store/{domain}/slice.ts` → `api.ts` → `index.ts`
3. Register in `src/store/index.ts`
4. Page → `src/pages/{domain}.tsx`
5. Route → `src/routes.tsx`

---

## 5. Design Style

- [ ] **The project must have a `DESIGN.md` file** at the root — if missing, copy the default one bundled with this skill (`react-rules/DESIGN.md`) to the project root and inform the user that a default design system has been applied
- [ ] **Read `DESIGN.md`** before building any UI — components and pages must follow it
- [ ] Flag any UI patterns that visibly contradict the documented design rules (e.g. wrong border-radius, wrong button size, wrong color usage, wrong typography)

When a `DESIGN.md` is present, read it before building any UI and follow it strictly:
- Match the spacing, color, corner style, and component patterns defined there
- Use `cn()` for all className merging
- Prefer shadcn primitives over custom-built UI elements

---

## Auditing a project

These rules are the source of truth for auditing as well. When reviewing an existing project against them, use the **`react-architect`** skill — it defines the review process and report format and audits against the rules above.
