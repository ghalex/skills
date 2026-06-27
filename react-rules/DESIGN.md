# Default — Style Reference
> Neutral shadcn/ui foundation.

**Theme:** light + dark (class-based)

The default design language is the clean, neutral **shadcn/ui (new-york)** foundation built on Tailwind CSS v4 and OKLCH color tokens. It is intentionally unbranded: a near-achromatic palette, a single moderate corner radius, and the system font stack. It is meant as a coherent, audit-clean starting point that a project customizes by editing the tokens in `src/main.css` and this document together.

This file is the **default** bundled with `react-rules`. When a project has no `DESIGN.md`, this one is copied to its root. Replace the tokens here when you brand the project — keep `DESIGN.md` and `src/main.css` in sync so audits stay meaningful.

## Tokens — Colors

All colors are defined as OKLCH CSS variables in `src/main.css` and exposed to Tailwind via `@theme inline`. Each has a `light` (`:root`) and `dark` (`.dark`) value. Use the semantic Tailwind utilities (`bg-background`, `text-foreground`, `bg-primary`, …) — never hardcode hex.

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

## Tokens — Typography

The default uses the **system font stack** — no custom font files. shadcn `new-york` style.

| Role | Family | Notes |
|------|--------|-------|
| UI / body | `ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, sans-serif` | All headings, body, and UI text |
| Code / mono | `ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace` | Code snippets, inputs that show code |

Use Tailwind's type scale (`text-xs` … `text-4xl`) and weights (`font-normal`, `font-medium`, `font-semibold`). Do not introduce custom font families without updating this file and `src/main.css`.

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

shadcn `Button`. `default` variant = `bg-primary text-primary-foreground`; `outline` = transparent with `border`; `ghost` = transparent, accent on hover; `destructive` = `bg-destructive`. `rounded-md`. Use variants — do not restyle inline.

### Card
**Role:** Content container

shadcn `Card` (`CardHeader`, `CardTitle`, `CardDescription`, `CardContent`, `CardFooter`). `bg-card text-card-foreground`, `rounded-xl`, subtle `border`. Group related content; let the card define padding.

### Input + Field
**Role:** Form element

shadcn `Input` with the `field` primitives (`Field`, `FieldGroup`, `FieldLabel`, `FieldDescription`). `bg-transparent`, `border-input`, `rounded-md`, focus uses `--ring`. **Always** compose forms with `FieldGroup` / `FieldLabel` / `FieldDescription` — never a bare `Label`.

## Do's and Don'ts

### Do
- Use semantic Tailwind tokens (`bg-background`, `text-foreground`, `bg-primary`, `text-muted-foreground`) so light/dark themes work automatically.
- Use `cn()` for all className merging.
- Prefer shadcn primitives over custom-built UI elements.
- Keep the single `--radius` system — `rounded-md` for controls, `rounded-lg`/`xl` for surfaces.
- Use the system font stack and Tailwind's type scale.

### Don't
- Don't hardcode hex/rgb colors or pixel radii — use the tokens.
- Don't introduce new font families or one-off colors without updating this file and `src/main.css` together.
- Don't edit files in `src/components/ui/` by hand.
- Don't use string concatenation for classNames.

## Surfaces

| Level | Token | Purpose |
|-------|-------|---------|
| 0 | `--background` | Base page background |
| 1 | `--card` / `--popover` | Cards, dropdowns, elevated surfaces |
| 2 | `--muted` / `--accent` | Subtle nested backgrounds, hover states |

## Quick Start

The tokens above are already defined in `src/main.css` (generated by `react-setup`) under `:root` and `.dark`, and wired to Tailwind via `@theme inline`. To rebrand the project, edit the OKLCH values in `src/main.css` and update the corresponding rows in this document so `react-architect` audits stay accurate.
