# Default — Style Reference
> Neutral shadcn/ui foundation.

**Theme:** light + dark (class-based)

The default design language is the clean, neutral **shadcn/ui (new-york)** foundation built on Tailwind CSS v4 and OKLCH color tokens. It is intentionally unbranded: a near-achromatic palette, a single moderate corner radius, and the `next/font` geist stack. It is meant as a coherent, audit-clean starting point that a project customizes by editing the tokens in `src/app/globals.css` and this document together.

This file is the **default** bundled with `nextjs-rules`. When a project has no `DESIGN.md`, this one is copied to its root. Replace the tokens here when you brand the project — keep `DESIGN.md` and `src/app/globals.css` in sync so audits stay meaningful.

## Tokens — Colors

All colors are defined as OKLCH CSS variables in `src/app/globals.css` and exposed to Tailwind via `@theme inline`. Each has a `light` (`:root`) and `dark` (`.dark`) value. Use the semantic Tailwind utilities (`bg-background`, `text-foreground`, `bg-primary`, …) — never hardcode hex.

| Token | Light | Dark | Role |
|-------|-------|------|------|
| `--background` | `oklch(1 0 0)` | `oklch(0.145 0 0)` | Page background |
| `--foreground` | `oklch(0.145 0 0)` | `oklch(0.985 0 0)` | Primary text |
| `--card` | `oklch(1 0 0)` | `oklch(0.205 0 0)` | Card / surface background |
| `--card-foreground` | `oklch(0.145 0 0)` | `oklch(0.985 0 0)` | Text on cards |
| `--popover` | `oklch(1 0 0)` | `oklch(0.205 0 0)` | Popover / dropdown background |
| `--primary` | `oklch(0.205 0 0)` | `oklch(0.922 0 0)` | Primary actions, filled buttons |
| `--primary-foreground` | `oklch(0.985 0 0)` | `oklch(0.205 0 0)` | Text on primary |
| `--secondary` | `oklch(0.97 0 0)` | `oklch(0.269 0 0)` | Secondary buttons / surfaces |
| `--secondary-foreground` | `oklch(0.205 0 0)` | `oklch(0.985 0 0)` | Text on secondary |
| `--muted` | `oklch(0.97 0 0)` | `oklch(0.269 0 0)` | Muted backgrounds, placeholders |
| `--muted-foreground` | `oklch(0.556 0 0)` | `oklch(0.708 0 0)` | Secondary / hint text |
| `--accent` | `oklch(0.97 0 0)` | `oklch(0.269 0 0)` | Hover / accent surfaces |
| `--accent-foreground` | `oklch(0.205 0 0)` | `oklch(0.985 0 0)` | Text on accent |
| `--destructive` | `oklch(0.577 0.245 27.325)` | `oklch(0.704 0.191 22.216)` | Errors, destructive actions |
| `--border` | `oklch(0.922 0 0)` | `oklch(1 0 0 / 10%)` | Borders, dividers |
| `--input` | `oklch(0.922 0 0)` | `oklch(1 0 0 / 15%)` | Input borders |
| `--ring` | `oklch(0.708 0 0)` | `oklch(0.556 0 0)` | Focus rings |

Sidebar surfaces (`--sidebar`, `--sidebar-foreground`, `--sidebar-primary`, `--sidebar-accent`, `--sidebar-border`, `--sidebar-ring`) mirror the same scale for the app shell.

Dark mode is class-based (`.dark` on `<html>`). Set it in the root `layout.tsx` with `suppressHydrationWarning` on `<html>` so a theme provider can swap the class without a hydration mismatch.

## Tokens — Typography

Fonts are loaded with **`next/font`** in `src/app/layout.tsx` and exposed as CSS variables — never via `<link>` tags or `@import`. shadcn `new-york` style.

| Role | Family | Notes |
|------|--------|-------|
| UI / body | `--font-sans` (Geist, falls back to `system-ui`) | All headings, body, and UI text |
| Code / mono | `--font-mono` (Geist Mono, falls back to `ui-monospace`) | Code snippets, inputs that show code |

Use Tailwind's type scale (`text-xs` … `text-4xl`) and weights (`font-normal`, `font-medium`, `font-semibold`). Do not introduce custom font families without updating this file, `layout.tsx`, and `globals.css` together.

## Tokens — Spacing & Shapes

**Density:** comfortable — use Tailwind's default spacing scale (`gap-2`, `gap-4`, `p-4`, `p-6`).

### Border Radius

Driven by a single base variable `--radius: 0.625rem` (10px), with derived steps:

| Token | Value | Use |
|-------|-------|-----|
| `--radius-sm` | `calc(var(--radius) - 4px)` | small controls, badges |
| `--radius-md` | `calc(var(--radius) - 2px)` | inputs, buttons |
| `--radius-lg` | `var(--radius)` | cards, popovers |
| `--radius-xl` | `calc(var(--radius) + 4px)` | large surfaces |

Use `rounded-md` for controls and `rounded-lg`/`rounded-xl` for cards. Do not hardcode pixel radii.

## Components

Components come from **shadcn/ui** primitives in `src/components/ui/`. Never custom-roll a primitive that shadcn provides — add it with `pnpm dlx shadcn@latest add <component>`.

### Button
**Role:** Interactive element

shadcn `Button`. `default` variant = `bg-primary text-primary-foreground`; `outline` = transparent with `border`; `ghost` = transparent, accent on hover; `destructive` = `bg-destructive`. `rounded-md`. Use variants — do not restyle inline. A submit button inside a Server Action form reads pending state from `useFormStatus` in its own small Client Component.

### Card
**Role:** Content container

shadcn `Card` (`CardHeader`, `CardTitle`, `CardDescription`, `CardContent`, `CardFooter`). `bg-card text-card-foreground`, `rounded-xl`, subtle `border`. Group related content; let the card define padding.

### Input + Field
**Role:** Form element

shadcn `Input` with the `field` primitives (`Field`, `FieldGroup`, `FieldLabel`, `FieldDescription`). `bg-transparent`, `border-input`, `rounded-md`, focus uses `--ring`. **Always** compose forms with `FieldGroup` / `FieldLabel` / `FieldDescription` — never a bare `Label`. Field errors come from the `useActionState` result of the Server Action, rendered in `FieldDescription`.

### Skeleton
**Role:** Loading placeholder

shadcn `Skeleton` inside `loading.tsx` and `<Suspense fallback>`. Match the shape and spacing of the content it replaces so streaming doesn't shift layout.

## Do's and Don'ts

### Do
- Use semantic Tailwind tokens (`bg-background`, `text-foreground`, `bg-primary`, `text-muted-foreground`) so light/dark themes work automatically.
- Use `cn()` for all className merging.
- Prefer shadcn primitives over custom-built UI elements.
- Keep the single `--radius` system — `rounded-md` for controls, `rounded-lg`/`xl` for surfaces.
- Load fonts with `next/font` and images with `next/image`.

### Don't
- Don't hardcode hex/rgb colors or pixel radii — use the tokens.
- Don't introduce new font families or one-off colors without updating this file and `globals.css` together.
- Don't edit files in `src/components/ui/` by hand.
- Don't use string concatenation for classNames.
- Don't mark a whole page `'use client'` just to style it — styling needs no client boundary.

## Surfaces

| Level | Token | Purpose |
|-------|-------|---------|
| 0 | `--background` | Base page background |
| 1 | `--card` / `--popover` | Cards, dropdowns, elevated surfaces |
| 2 | `--muted` / `--accent` | Subtle nested backgrounds, hover states |

## Quick Start

The tokens above live in `src/app/globals.css` under `:root` and `.dark`, wired to Tailwind via `@theme inline`. To rebrand the project, edit the OKLCH values there and update the corresponding rows in this document so `nextjs-architect` audits stay accurate.
