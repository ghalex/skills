# Mermaid Authoring Guide

You write Mermaid **text**; the template's Mermaid.js renders it. Never produce
image files.

Two styling rules:
- **Architecture diagram (Tab 1):** styling is ENCOURAGED here — brand-logo icons
  on nodes + `classDef` layer colors. This is the one diagram meant to look alive.
- **Every other diagram (incl. ER):** inherit the theme; no colors, no icons.
- **Never** use `%%{init}%%` directives anywhere — the template owns initialization
  (theme, palette, icon pack, flowchart/ER config). `classDef`/`class` are allowed.

## How to embed

Put the diagram inside a `pre.mermaid` block in the tab body. The architecture
diagram additionally gets the `arch` class (this enables its subtle edge animation
and hover lift — apply it ONLY to the architecture flowchart):

```html
<pre class="mermaid arch">
flowchart TB
  a["Client"] --> b["API"]
</pre>
```

All other diagrams use a plain block:

```html
<pre class="mermaid">
erDiagram
  A ||--o{ B : has
</pre>
```

## Rules

- Keep diagrams **system-level**, not file-by-file. Architecture: a generous
  overview — aim for ~12–20 nodes organized into labeled layer subgraphs.
- Every node/entity must correspond to a real, detected component — no invented boxes.
- Quote labels with spaces/punctuation: `api["FastAPI API"]`.
- Labels wrap automatically (htmlLabels is on); keep them short — 1–3 words. Use
  `<br/>` only for an intentional line break.
- **Verify it renders.** In Phase 6 you open the output HTML in a browser. Confirm
  every Mermaid block shows actual nodes — not blank, no console parse error. A
  blank diagram is a failure; fix it before finishing (see the fallback rule below).

---

## Tab 1 — Architecture diagram (layered, logos + color + labeled edges)

A **generous overview**: group nodes into labeled layer `subgraph`s (Client Apps →
API Layer → Data → External & Integrations), and **label the key edges** with the
protocol/purpose (REST, WS, ORM, enqueue, push, pay, geocode, traces…). Break the
external integrations out into their real distinct services rather than lumping
them — it's the extra detail that makes the diagram useful.

**Use `flowchart LR`** (left-right). Mermaid largely **ignores a per-subgraph
`direction`** when nodes have edges crossing subgraph boundaries (they do here), so
don't set inner `direction` — pick the global direction instead. `LR` lays the
layers out as readable columns; `TB` tends to stack everything into one tall strip.

Each node carries a brand logo as an inline `<img>` in its label, plus a layer
color via `classDef`. **Use `<img>`-in-label nodes — NOT Mermaid icon-shape nodes
(`@{ icon: ... }`).** Icon-shape nodes size to the icon and clip any label longer
than the icon ("FastAPI" → "FastAF"); `<img>`-in-label nodes auto-size to content.

**Logo node syntax:**

```
id["<img src='https://api.iconify.design/logos/fastapi-icon.svg' height='26'/><br/>REST API<br/>/v1"]
```

- The `<img>` pulls the brand SVG from Iconify's API (works because the template
  sets `securityLevel:'loose'` + `htmlLabels:true`). `height='26'` keeps logos even.
- Use `<br/>` for the label and an optional second detail line (e.g. `/v1`).
- Nodes with no single brand (e.g. "Mailgun + Twilio", "postcodes.io") are plain
  text nodes — no `<img>`. That's expected.

**Edge label syntax:** `api -->|ORM| db` · dotted with label: `api -. traces .-> obs`.

**Full example (monorepo: client apps → API → data → external):**

```html
<pre class="mermaid arch">
flowchart LR
  subgraph clients["Client Apps"]
    ios["<img src='https://api.iconify.design/logos/apple.svg' height='26'/><br/>iOS"]
    and["<img src='https://api.iconify.design/logos/android-icon.svg' height='26'/><br/>Android"]
    web["<img src='https://api.iconify.design/logos/react.svg' height='26'/><br/>Web app"]
    site["<img src='https://api.iconify.design/logos/react.svg' height='26'/><br/>Marketing site"]
  end

  subgraph apiLayer["API Layer · FastAPI"]
    api["<img src='https://api.iconify.design/logos/fastapi-icon.svg' height='26'/><br/>REST API<br/>/v1"]
    ws["WebSocket<br/>Chat"]
    jobs["Background<br/>Jobs"]
    ai["<img src='https://api.iconify.design/logos/openai-icon.svg' height='26'/><br/>AI Agents"]
  end

  subgraph dataLayer["Data"]
    db["<img src='https://api.iconify.design/logos/postgresql.svg' height='26'/><br/>PostgreSQL"]
    imgs["Image Store<br/>/images"]
  end

  subgraph extLayer["External &amp; Integrations"]
    auth["Apple / Google<br/>Sign-in"]
    pay["<img src='https://api.iconify.design/logos/stripe.svg' height='26'/><br/>Apple IAP<br/>+ Stripe"]
    fcm["<img src='https://api.iconify.design/logos/firebase.svg' height='26'/><br/>Firebase FCM"]
    comms["Mailgun<br/>+ Twilio"]
    geo["postcodes.io"]
  end

  ios -->|REST| api
  and -->|REST| api
  web -->|REST| api
  site -->|REST| api
  ios -. WS .-> ws
  and -. WS .-> ws
  api --> ws
  api -->|enqueue| jobs
  api --> ai
  api -->|ORM| db
  api -->|uploads| imgs
  api -->|verify token| auth
  api -->|pay + webhooks| pay
  api -->|push| fcm
  api -->|email / SMS| comms
  api -->|geocode| geo

  classDef mobile fill:#eaf0fb,stroke:#b9c9ec,color:#2b2f36;
  classDef webl fill:#e8f6f4,stroke:#b4ddd6,color:#2b2f36;
  classDef backend fill:#eceafb,stroke:#c6bff0,color:#2b2f36;
  classDef data fill:#eef1f6,stroke:#c3ccda,color:#2b2f36;
  classDef external fill:#fbf3e6,stroke:#ecd9b4,color:#2b2f36;
  class ios,and mobile;
  class web,site webl;
  class api,ws,jobs,ai backend;
  class db,imgs data;
  class auth,pay,fcm,comms,geo external;
</pre>
```

Subgraph ids (`clients`, `apiLayer`, …) must not collide with node ids or classDef
names. Apply `classDef` colors to the inner nodes (subgraph boxes stay neutral).

**Layer color palette** (all pale; reuse these):
mobile `#eaf0fb` · web `#e8f6f4` · backend `#eceafb` · data `#eef1f6` · external `#fbf3e6`.
Group external services (Stripe, Twilio, Mailgun, postcodes.io, etc.) into the
`external` class so the diagram reads layer-by-layer.

**Logo name mapping** (Iconify `logos:` set — the URL is
`https://api.iconify.design/logos/<name>.svg`):

| Tech | name | Tech | name |
|---|---|---|---|
| Apple/iOS | `apple` | Docker | `docker-icon` |
| Android | `android-icon` | PostgreSQL | `postgresql` |
| FastAPI | `fastapi-icon` | MySQL | `mysql` |
| React | `react` | MongoDB | `mongodb` |
| Vue | `vue` | Redis | `redis` |
| Swift | `swift` | Firebase | `firebase` |
| Kotlin | `kotlin-icon` | OpenAI | `openai-icon` |
| Python | `python` | Stripe | `stripe` |
| TypeScript | `typescript-icon` | AWS | `aws` |
| Tailwind | `tailwindcss-icon` | Google Cloud | `google-cloud` |
| Vite | `vitejs` | Nginx | `nginx` |
| Node.js | `nodejs-icon` | GraphQL | `graphql` |

**Fallback rule (never ship a blank/broken diagram):** name suffixes vary
(`-icon` vs plain). If you are unsure a name exists, or after rendering a logo is a
broken-image box, drop the `<img>` for that node and use a plain colored text node
— keep the `classDef` color:

```
api["FastAPI"]
class api backend;
```

A colored node without a logo is perfectly fine. A blank or broken diagram is not.
Render once; if any logo is broken, fall back to a plain colored node and move on.

---

## Tab 3 — ER diagram (domain-split, complete, PK/FK)

Do NOT draw all tables in one diagram. Split the schema into 3–5 **domain groups**
(e.g. Users & Auth, Listings & Swaps, Payments & Credits, AI/Identify, Messaging).
Emit one `<h3>` heading + one plain `<pre class="mermaid">erDiagram…</pre>` per
domain. **Every detected table must appear in exactly one domain** — do not drop
tables; completeness is the goal (this is the screenshot-quality look the user wants).

For each entity, list its key columns with **type** and **PK/FK** markers:
- Always include the primary key (`PK`) and every foreign key (`FK`).
- Include the handful of salient columns that explain the entity (name, status,
  amount, email, timestamps). You need not list every column, but never invent one
  — use only columns present in the model/migration source.
- Attribute line format: `<type> <name> <key?>` → `uuid id PK`, `uuid user_id FK`,
  `string email`, `timestamp created_at`.

Use crow's-foot cardinality and label every relationship with a verb. Cross-domain
FKs: show the referenced entity in whichever domain it primarily belongs, and you
may repeat a minimal stub of it in another domain to render the relationship.

**Example (one domain):**

```html
<h3>Users &amp; Auth</h3>
<pre class="mermaid">
erDiagram
  USERS ||--o{ SESSIONS : "has"
  USERS ||--o{ CREDITS : "owns"
  USERS {
    uuid id PK
    string email
    string google_user_id
    timestamp created_at
  }
  SESSIONS {
    uuid id PK
    uuid user_id FK
    timestamp expires_at
  }
  CREDITS {
    uuid id PK
    uuid user_id FK
    int amount
  }
</pre>
```

Repeat for each domain. After all domains, add ONE "Source evidence" line for the
whole Database tab citing the model/migration files you read.

**Cardinality cheat sheet:** `||--||` one-to-one · `||--o{` one-to-many ·
`}o--o{` many-to-many · `}o--||` many-to-one. The crow's-foot end (`o{` / `}o`)
goes on the "many" side.
