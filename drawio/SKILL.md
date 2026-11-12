---
name: drawio
description: Draw or edit draw.io diagrams (.drawio XML) in a plain boxes-and-arrows house style - machines as boxes, a coloured box per component, an OS bar, labelled orthogonal arrows. Use for architecture diagrams, request or data flow diagrams, and network or deployment diagrams, or when the user says "draw a diagram", "drawio", "diagrams.net", "architecture diagram", "show how X reaches Y", or names a .drawio file.
---

# draw.io diagrams

A `.drawio` file is plain XML: read it and write it directly. This skill is the house style, the
rules that keep a hand-written file valid, and the steps around drawing one.

- `examples/architecture.drawio`: a system overview (frontend, API, worker and database on three servers).
- `examples/request-path.drawio`: one request (a login) followed step by step, with numbered arrows.
- `references/drawio-xml.md`: the XML rules and style keys, with links to draw.io's own reference.
- `scripts/validate.py`: checks a file's structure. Run it on every file you write.

Read the example closest to what was asked before writing: copy its cells and change them, rather
than composing style strings from memory.

## Steps

1. **Get the facts from the source.** A diagram of a system is a claim about it. Read the code,
   config and docs for the names, ports, protocols and who calls whom. Do not draw a guess as if
   it were known: tell the user what you assumed (for example, which parts share a machine).
2. **Pick one question the diagram answers** and put it in the title: "how a login reaches the
   database", "which servers the app runs on". Leave out what does not help answer it. Two
   small diagrams beat one that shows everything.
3. **Look at what is already there.** Read the diagrams next to the one you are writing and reuse
   their colours and names. If the user edited a diagram you drew, their version is the style.
4. **Lay it out on paper first**: list every box with x, y, width, height, then the arrows.
   Generating the XML from a short script (a list of boxes and arrows) is fine and keeps the
   arithmetic honest; the file you deliver is the XML only.
5. **Write the file**, run `python3 scripts/validate.py <file>`, and fix every error.
6. **Say what you could not check.** Without draw.io you cannot see the result, so label overlap
   and arrow routing are unverified: say so, and expect the user to nudge things. If the `drawio`
   CLI is installed, export a PNG (`drawio -x -f png -o out.png file.drawio`) and look at it.
7. **Link it** from the folder's README if the repo keeps one (see "Links").

Write a new file unless the user says to replace one, and never overwrite a diagram you have not
read. Commit only when asked.

## House style

**Machines are plain boxes, drawn first.** A server, VM or host is an empty white rectangle
(`whiteSpace=wrap;html=1;`, empty `value`). Its name is a separate text cell above or below it:
bold name, then one short fact ("public IP", "private network"). What runs on the machine
is drawn on top of it as ordinary cells on the default layer, with canvas coordinates: no
`container=1`, no groups. The machine cell comes before its contents in the file so it sits behind.

**A bar at the bottom of each machine** names the operating system or runtime:
`rounded=0;whiteSpace=wrap;html=1;`, 30 high, as wide as the contents ("LINUX", "LINUX · Docker").

**Components are filled boxes**, name in bold on the first line, then at most two lines saying
what it does or where it listens (":443, ends TLS"). A daemon that fronts a machine can be a wide
bar across the top instead of a box.

**Colour means the component, not decoration.** One colour per component, the same in every
diagram of the project:

| Fill / stroke | Use |
|---|---|
| none (white) | machines, people, OS bars, anything neutral |
| `#f8cecc` / `#b85450` red | the project's process that runs on many machines (worker, agent, host daemon) |
| `#dae8fc` / `#6c8ebf` blue | the project's central service (API, control plane) |
| `#e1d5e7` / `#9673a6` purple | a second service of the project (frontend, proxy, edge) |
| `#ffe6cc` / `#d79b00` orange | infrastructure from someone else (Nginx, Traefik, Redis, DNS), or "other" instances |
| `#d5e8d4` / `#82b366` green | where the data lives, or the thing the diagram is about (the database, the user's VM) |

If a project already has diagrams, its colours win over this table.

**People** (visitor, developer) are plain boxes on the left. Requests flow left to right, or top
to bottom from a central service to the machines it manages.

**Arrows** are orthogonal:
`edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;defaultLabelBackgroundColor=page;`

- Solid for the path the diagram is about; `dashed=1;` for background or setup traffic (polling,
  verification, a side channel such as SSH).
- A label says protocol and port, then what travels: `HTTPS :443<br>POST /api/login`. Break
  lines with `<br>`: edge labels do not wrap. In a request path, number the steps: `1. …`, `2. …`.
- An arrow between two boxes on the same row must be a straight line. Give both boxes the same
  vertical centre, or pin the ends with `exitX/exitY/entryX/entryY` (see the reference).
- Two arrows between the same pair of boxes: pin them at different heights (0.3 and 0.85), label
  one above the line (`verticalAlign=bottom;`) and one below (`verticalAlign=top;`).
- An arrow to a whole machine starts or ends on the machine cell; an arrow to a component, on the
  component.

**Text**: a title top left (`fontSize=16`, bold name, then the question in brackets). Notes that
belong to no box go in a text cell at the bottom, one or two sentences. Use the names the code
uses. No drop shadows, gradients, rounded corners or icons unless the user adds them; an embedded
image must be a small icon, since a large `data:` URI makes the file too big to read.

## Layout numbers

These come from the examples and are known to read well:

- Grid of 10. Component boxes 150 to 200 wide, 80 to 110 high. Bars 30 to 70 high.
- 20 padding between a machine's edge and its contents; 20 between contents.
- Leave room for the label: 140 or more between boxes joined by a labelled arrow, 180 to 250 for
  a two- or three-line label. An unlabelled arrow needs 60.
- 200 between rows of machines when labelled arrows cross the gap.
- Machine names sit 30 to 40 above the machine, or below it when arrows enter from the top.
- Set `pageWidth` and `pageHeight` to fit the drawing (for example 1600 x 900).

## File rules

- Full format: `<mxfile host="app.diagrams.net"><diagram name="Page-1" id="…"><mxGraphModel …>`.
  Give the `<diagram>` a readable, stable `id` (`shop-architecture`): links point at it.
- Cell ids are short and readable with one prefix per file: `shop-nginx`, `shop-e1`. Keep the ids
  of cells you did not change, including the ones draw.io generated for the user's own cells.
- `<mxCell id="0"/>` and `<mxCell id="1" parent="0"/>` come first; everything else has
  `parent="1"`.
- Labels are HTML (`html=1`), so the `value` attribute is XML-escaped HTML: `<b>` is written
  `&lt;b&gt;`, and a literal `<url>` shown to the reader is `&amp;lt;url&amp;gt;`.
- No XML comments, no compressed content, `1`/`0` never `true`/`false`, no spaces in style strings.
- Edit an existing file in place and touch only the cells you mean to: the user moves things by
  hand, and their geometry is theirs.

## Links

A diagram in a public GitHub repo opens in draw.io from a link, which is worth putting in the
folder's README next to a line on what the diagram shows:

```
https://app.diagrams.net/#H<owner>%2F<repo>%2F<branch>%2F<path with %2F>#%7B%22pageId%22%3A%22<diagram id>%22%7D
```

For `shop/architecture.drawio` on `main` of `alice/drawings`, page id `shop-architecture`:

```
https://app.diagrams.net/#Halice%2Fdrawings%2Fmain%2Fshop%2Farchitecture.drawio#%7B%22pageId%22%3A%22shop-architecture%22%7D
```

The link reads the file from GitHub, so it works once the file is pushed. `validate.py` prints
each file's page ids.
