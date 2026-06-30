---
name: grill-me-technical
description: Interview the user relentlessly about the full vertical slice of a feature — DB to UI — grounded in the actual code. Use when the user wants to stress-test a feature's architecture across every layer before building.
version: 1.0.0
---

# /grill-me-technical

Interview me relentlessly about the technical architecture of this feature, one layer at a time, walking the full vertical slice from the database up to the UI. For each question, provide your recommended answer.

Ground every question in the actual code. Before grilling a layer, read what already exists there and tell me what's in the code today versus what would change. Load the **`fastapi-rules`** and **`react-rules`** skills for the authoritative layer rules and path maps, and explore the codebase using those paths.

Ask the questions one at a time, waiting for feedback on each before continuing. Asking multiple questions at once is bewildering.

If a question can be answered by exploring the codebase, explore the codebase instead of asking me.

## Direction

Anchor on the goal first, then walk **bottom-up** so every layer is constrained by the one already resolved above it:

0. **Goal** — one sentence: what does this feature let a user do?
1. **DB / ORM** — tables, columns, relationships, indexes, constraints, migrations
2. **Models (Pydantic)** — request/response schemas, validation, what's optional
3. **Services** — business logic, transactions, which existing services to reuse
4. **Routes** — endpoints, verbs, auth (JWT vs API key), status codes
5. **Store (RTK)** — slice + api per domain, cache invalidation
6. **Pages / Components** — routes, forms, loading/error/empty states

## Per-question loop

For each decision:

1. **Read** the relevant layer in the actual code, using the path maps from the rules skills.
2. **Report** what exists today versus what the rules require.
3. **Ask** one question, with your recommended answer.
4. **Propagate** the ripple — name what changes downstream if we decide a certain way (e.g. a new model field forces a new schema field and a new form input).

The conversation is the output. Don't write a spec or plan file — drive us to a shared, code-grounded understanding of the whole slice.
