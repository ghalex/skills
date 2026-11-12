#!/usr/bin/env python3
"""Check a .drawio file against draw.io's generation checklist. Stdlib only.

    python3 validate.py diagram.drawio [more.drawio ...]

Prints one line per problem and exits 1 if any file has one. On success prints each page's id,
which is what a draw.io deep link needs. It checks structure, not looks: open the file to see it.
"""
import re
import sys
import xml.etree.ElementTree as ET

BIG_IMAGE = 20_000  # bytes of one embedded image before it is worth a warning


def check(path):
    errors, warnings = [], []
    text = open(path, encoding="utf-8").read()
    if "<!--" in text:
        errors.append("XML comments are not allowed in a diagram file")
    try:
        root = ET.fromstring(text)
    except ET.ParseError as err:
        return [f"not well-formed XML: {err}"], warnings, []
    if root.tag == "mxGraphModel":
        diagrams = [(None, root)]
    elif root.tag == "mxfile":
        if root.get("compressed") == "true":
            errors.append('compressed="true": write plain XML')
        diagrams = []
        for d in root.findall("diagram"):
            model = d.find("mxGraphModel")
            if model is None:
                errors.append(f"page {d.get('id')!r} holds no <mxGraphModel> (compressed content?)")
            else:
                diagrams.append((d.get("id"), model))
        ids = [i for i, _ in diagrams]
        if not diagrams:
            errors.append("no <diagram> in <mxfile>")
        if None in ids or len(set(ids)) != len(ids):
            errors.append("every <diagram> needs its own id")
    else:
        return [f"root element is <{root.tag}>, expected <mxfile> or <mxGraphModel>"], warnings, []

    for page, model in diagrams:
        where = f"page {page}: " if page else ""
        by_id, seen = {}, set()
        for holder in list(model.find("root") if model.find("root") is not None else []):
            cell = holder if holder.tag == "mxCell" else holder.find("mxCell")
            cid = holder.get("id")
            if cell is None or cid is None:
                errors.append(f"{where}a cell without an id or an <mxCell>")
                continue
            if cid in seen:
                errors.append(f"{where}id {cid!r} is used twice")
            seen.add(cid)
            by_id[cid] = cell
        if "0" not in by_id or by_id.get("1") is None or by_id["1"].get("parent") != "0":
            errors.append(f'{where}needs <mxCell id="0"/> and <mxCell id="1" parent="0"/>')
        for cid, cell in by_id.items():
            if cid == "0":
                continue
            name = f"{where}cell {cid!r}"
            if cell.get("parent") not in by_id:
                errors.append(f"{name}: parent {cell.get('parent')!r} does not exist")
            vertex, edge = cell.get("vertex") == "1", cell.get("edge") == "1"
            if vertex and edge:
                errors.append(f"{name}: both vertex and edge")
            if cid != "1" and cell.get("parent") == "1" and not (vertex or edge):
                errors.append(f"{name}: neither vertex=\"1\" nor edge=\"1\"")
            style = cell.get("style") or ""
            if re.search(r"\s[=;]|[=;]\s", re.sub(r"image=data:[^;]*;?", "", style)) and "dashPattern" not in style:
                errors.append(f"{name}: spaces around = or ; in its style")
            if re.search(r"=(true|false)(;|$)", style):
                errors.append(f"{name}: true/false in its style, use 1/0")
            image = re.search(r"image=data:[^;]*", style)
            if image and len(image.group(0)) > BIG_IMAGE:
                warnings.append(f"{name}: embedded image of {len(image.group(0)) // 1000} KB; use a small icon or a URL")
            geo = cell.find("mxGeometry")
            if vertex:
                if geo is None or any(geo.get(k) is None for k in ("width", "height")):
                    errors.append(f"{name}: a vertex needs mxGeometry with width and height")
                elif float(geo.get("width")) < 0 or float(geo.get("height")) < 0:
                    errors.append(f"{name}: negative width or height")
            if edge:
                if geo is None or geo.get("relative") != "1":
                    errors.append(f'{name}: an edge needs <mxGeometry relative="1" as="geometry"/>')
                for end in ("source", "target"):
                    ref = cell.get(end)
                    if ref is None:
                        warnings.append(f"{name}: no {end}, the arrow is not attached")
                    elif ref not in by_id:
                        errors.append(f"{name}: {end} {ref!r} does not exist")
    return errors, warnings, [i for i, _ in diagrams if i]


def main(paths):
    if not paths:
        print(__doc__)
        return 2
    failed = False
    for path in paths:
        errors, warnings, pages = check(path)
        for line in errors:
            print(f"{path}: ERROR {line}")
        for line in warnings:
            print(f"{path}: warning {line}")
        if errors:
            failed = True
        else:
            print(f"{path}: ok, page ids: {', '.join(pages) or '(bare mxGraphModel)'}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
