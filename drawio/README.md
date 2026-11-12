# drawio

Claude Code skill to draw and edit [draw.io](https://www.drawio.com) diagrams as plain `.drawio` XML, in one consistent boxes-and-arrows style.

## Install

```bash
npx skills add ghalex/skills --skill drawio
```

## Usage

```
claude "draw an architecture diagram of this project in docs/architecture.drawio"
claude "draw how a request gets from the browser to the database"
claude "add the worker to docs/architecture.drawio"
```

## What it does

1. Reads the code and config for the real names, ports and who calls whom
2. Reads the diagrams already in the repo and keeps their colours and names
3. Lays out machines, components and arrows in the house style and writes the XML
4. Validates the file with `scripts/validate.py` (draw.io's generation checklist)
5. Says what it assumed and what it could not check without opening draw.io
6. Adds a link that opens the diagram in draw.io to the folder's README, when there is one

## What is in it

- `SKILL.md`: the steps, the house style, layout numbers and file rules
- `references/drawio-xml.md`: the XML rules and style keys, with links to draw.io's reference
- `examples/`: an architecture diagram and a numbered request path to copy from
- `scripts/validate.py`: structure check for `.drawio` files (Python 3, no dependencies)
