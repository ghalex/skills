# draw.io XML reference

A short version of draw.io's own guidance for generated diagrams. The originals, for anything
not covered here (unusual shapes, stencil libraries, layouts):

- Overview and rules: https://www.drawio.com/docs/reference/diagram-generation/
- Style reference (every key and value, validation checklist):
  https://www.drawio.com/docs/reference/diagram-generation/style-reference/
- Schema: https://github.com/jgraph/drawio-mcp/blob/main/shared/mxfile.xsd

## Skeleton

```xml
<mxfile host="app.diagrams.net">
  <diagram name="Page-1" id="my-diagram">
    <mxGraphModel dx="1600" dy="900" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1600" pageHeight="900" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        <mxCell id="shop-api" parent="1" style="whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" value="&lt;b&gt;api&lt;/b&gt;&lt;div&gt;:8080&lt;/div&gt;" vertex="1">
          <mxGeometry x="400" y="140" width="200" height="90" as="geometry" />
        </mxCell>
        <mxCell id="shop-db" parent="1" style="whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;" value="&lt;b&gt;Postgres&lt;/b&gt;" vertex="1">
          <mxGeometry x="760" y="140" width="190" height="90" as="geometry" />
        </mxCell>
        <mxCell id="shop-e1" parent="1" edge="1" source="shop-api" target="shop-db" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;defaultLabelBackgroundColor=page;" value="SQL :5432">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

A bare `<mxGraphModel>` is also a valid file, but use the full format: the `<diagram id>` is what
a link to the page needs.

## Rules

- Cells `0` and `1` are mandatory. Every other cell's `parent` must exist.
- Every id is unique in the diagram.
- A cell is a shape (`vertex="1"`) or a connector (`edge="1"`), never both.
- A vertex has `<mxGeometry x y width height as="geometry"/>`. Origin is top left, x grows right,
  y grows down. No negative sizes.
- An edge has `<mxGeometry relative="1" as="geometry"/>` and `source` / `target` cell ids.
- A style is `key=value;key=value;` with no spaces. Booleans are `1` and `0`.
- `value` is XML-escaped: `&lt; &gt; &amp; &quot;`. With `html=1` it is escaped HTML.
- Plain XML only: no `compressed="true"`, no XML comments.
- A child of a container (`parent` = the container's id) has coordinates relative to it. The house
  style avoids containers, so everything is on parent `1` with canvas coordinates.
- A non-rectangular shape needs its perimeter: `ellipse;perimeter=ellipsePerimeter;`,
  `rhombus;perimeter=rhombusPerimeter;`.

## Styles used by the house style

| What | Style |
|---|---|
| Box | `whiteSpace=wrap;html=1;` plus `fillColor=#…;strokeColor=#…;` |
| Square box | add `aspect=fixed;` |
| Bar | `rounded=0;whiteSpace=wrap;html=1;` |
| Text | `text;html=1;whiteSpace=wrap;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;rounded=0;` |
| Title | the text style with `align=left;fontSize=16;` |
| Arrow | `edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;defaultLabelBackgroundColor=page;` |
| Dashed arrow | add `dashed=1;` |
| Arrow both ways | add `startArrow=classic;startFill=1;` |
| Small icon | `shape=image;aspect=fixed;imageAspect=0;image=<url or small data: URI>;` |

## Arrows

- **Where an arrow leaves and arrives**: `exitX`, `exitY`, `entryX`, `entryY` are fractions of
  the box, 0 = left or top, 1 = right or bottom. Add `exitDx=0;exitDy=0;entryDx=0;entryDy=0;`.
  Leaving the right side a third of the way down and arriving at the middle of the left side:
  `exitX=1;exitY=0.33;exitDx=0;exitDy=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;`
- **A straight line** between two boxes needs both ends at the same canvas y (or x). To hit
  canvas y on a box: `(y - box.y) / box.height`.
- **Waypoints** force a route around something:

  ```xml
  <mxGeometry relative="1" as="geometry">
    <Array as="points"><mxPoint x="300" y="520" /><mxPoint x="300" y="115" /></Array>
  </mxGeometry>
  ```
- **Label**: the edge's `value`. `verticalAlign=bottom;` puts it above a horizontal line,
  `verticalAlign=top;` below. To slide it along the line, set `x` (-1 to 1) on the edge's
  `mxGeometry`; `y` is the offset from the line in pixels.
- **Arrow heads**: `endArrow` and `startArrow` (`classic`, `block`, `open`, `none`), filled with
  `endFill` / `startFill`.
- Other `edgeStyle` values: `elbowEdgeStyle` (with `elbow=horizontal|vertical`),
  `entityRelationEdgeStyle`; leave it out for a straight line.

## Other keys worth knowing

- Fill and stroke: `fillColor`, `strokeColor`, `strokeWidth`, `dashed`, `dashPattern=8 8`,
  `opacity`. Colours are `#RRGGBB` or `none`.
- Font: `fontSize`, `fontColor`, `fontStyle` (1 bold, 2 italic, 4 underline, added together),
  `align`, `verticalAlign`, `spacing`.
- Label outside a shape: `verticalLabelPosition=bottom;verticalAlign=top;` (under an icon).
- Shapes: `ellipse`, `rhombus`, `cylinder3` (a database), `cloud`, `document`, `note`,
  `shape=umlActor`. The house style uses rectangles; reach for these only when asked.

## Checklist before delivering

`scripts/validate.py` covers 1 to 9 and 13.

1. Well-formed XML, properly escaped.
2. `<mxfile>` root with at least one `<diagram>`.
3. Each diagram has a unique `id`.
4. `<mxCell id="0"/>` and `<mxCell id="1" parent="0"/>` are there.
5. All cell ids are unique.
6. Every `parent` exists.
7. Each cell is a vertex or an edge, not both.
8. Edge `source` and `target` exist.
9. Vertices have x, y, width, height; edges have `relative="1"`.
10. Styles are `key=value;` with valid keys.
11. Non-rectangular shapes have a matching perimeter.
12. HTML in `value` is escaped.
13. No negative sizes.
14. Children of a container use coordinates relative to it.
