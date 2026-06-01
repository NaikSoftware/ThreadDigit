# The `.emb.svg` Embroidery Format

`.emb.svg` stores a machine embroidery design as a standard SVG file with extra
embroidery data attached. Any SVG viewer opens it and shows a preview. Ink/Stitch
opens it and reads the stitch parameters, because the format reuses Ink/Stitch's
own namespace. A converter reads it to produce a DST, PES, or JEF file.

The double extension is deliberate. The file is valid SVG, so the operating
system and image viewers treat `design.emb.svg` like any other `.svg`. The
`.emb` part tells our own tools that the file carries embroidery data.

## Parametric, not a flat stitch dump

A design is a list of *elements*. Each element is one SVG shape with an
embroidery meaning: a running-stitch line, a fill area, a satin column, or a
sequence of manual stitches. Most elements store geometry and parameters, not
individual needle points; a converter generates the stitches from them. The one
exception is manual stitches, where the shape's vertices are the exact needle
points.

This is the same model Ink/Stitch uses. It keeps the file small and editable,
and it lets you change a parameter (row spacing, satin width) without
regenerating coordinates. The format produced from algorithm output uses manual
elements, since the algorithm already computes explicit stitches.

## Namespaces

The file uses two custom namespaces alongside standard SVG:

- `xmlns:inkstitch="http://inkstitch.org/namespace"` carries the stitch
  parameters. The names match Ink/Stitch exactly, so Ink/Stitch reads them.
- `xmlns:emb="http://thread-digit.app/embroidery/v1"` carries data Ink/Stitch
  has no concept of: the element-type discriminator, the thread-catalog
  reference, the thread palette, and any future parameters we add.

A generic viewer ignores both. Ink/Stitch ignores the `emb` namespace. Our
reader uses both.

## Coordinate system

- Units are millimeters. The root sets `emb:units="mm"`.
- The origin is the top-left corner, Y points down (the SVG convention).
- Coordinates are absolute.
- `viewBox="0 0 W H"` with `width="Wmm" height="Hmm"` makes one user unit equal
  one millimeter.

Ink/Stitch derives its millimeter scale from the declared physical size, so
millimeter coordinates are read correctly. This avoids the pixel-at-96-DPI
scaling that trips up hand-built Ink/Stitch files. Keep the `viewBox` aspect
ratio equal to the `width`/`height` ratio so the scale stays uniform.

## Document structure

```
<svg>                                 mm coordinate space, three namespaces
  <metadata>
    <emb:design>                      design-level metadata
      <emb:palette>
        <emb:thread/>                 one per thread: catalog, code, name, rgb
  <polyline|polygon|path .../>        one per element, in stitching order
```

Document order is stitching order. The first element in the file stitches first.

### Root `<svg>`

| Attribute | Meaning |
|-----------|---------|
| `xmlns` | Standard SVG namespace. |
| `xmlns:inkstitch` | `http://inkstitch.org/namespace`. |
| `xmlns:emb` | `http://thread-digit.app/embroidery/v1`. |
| `width`, `height` | Design size with the `mm` suffix. |
| `viewBox` | `0 0 W H` in millimeters. |
| `emb:version` | Format version, currently `2.0`. |
| `emb:units` | Coordinate units, currently `mm`. |

### `<emb:design>`

Inside the standard `<metadata>` element. `name`, `author`, `notes`, and
`created` (ISO-8601) are written only when set. `elementCount`, `widthMm`, and
`heightMm` are always written.

### `<emb:palette>` and `<emb:thread>`

The palette holds the thread catalog. An element refers to a thread by `id`.

| Attribute | Meaning |
|-----------|---------|
| `id` | Thread identifier referenced by elements. |
| `catalog` | Manufacturer or catalog, for example `Madeira`. |
| `code` | Catalog color code. |
| `name` | Color name. |
| `rgb` | Display color as `#RRGGBB`. |
| `percentage` | Thread blend percentage, default 100. |

The reader treats the palette as the source of truth for color. An element with
`emb:threadId` takes its full color (name, code, catalog, percentage) from the
palette, not from the `stroke`/`fill`, which exist for the preview.

## Element types

Every element carries these common attributes:

- `emb:elementType` — the authoritative type discriminator. The reader trusts
  it. A file without it falls back to Ink/Stitch-style detection.
- `emb:threadId` — palette reference (omitted when the element is standalone).
- `inkstitch:trim_after="true"` / `inkstitch:stop_after="true"` — machine trim
  and stop, written only when set. Ink/Stitch honors these too.
- any element parameters as `inkstitch:<name>="<value>"`, and any extension
  parameters as `emb:<name>="<value>"`.

A styling rule keeps Ink/Stitch from misreading an element. Ink/Stitch turns any
shape with a fill into a fill region, and an unstyled fill defaults to black. So
stroke-based elements set `fill="none"` and fill-based elements set
`stroke="none"`. The writer always does this.

### Line (running stitch)

`emb:elementType="line"`, an open `<polyline>` stroked with the thread color.
`inkstitch:stroke_method="running_stitch"`. Parameters:
`running_stitch_length_mm` (default 2.5), `repeats`, `bean_stitch_repeats`. The
polyline vertices are the path; the converter lays stitches along it.

### Manual stitches

`emb:elementType="manual_stitch"`, an open `<polyline>` with
`inkstitch:stroke_method="manual_stitch"`. The vertices are the exact needle
points. This is the element built from algorithm output.

### Fill and photo embroidery

`emb:elementType="fill"` (or `"photo_stitch"`), a `<polygon>` filled with the
thread color and `stroke="none"`. A fill with holes uses a `<path>` instead, one
`M … Z` subpath per ring with `fill-rule="evenodd"` (the first ring is the
outer boundary). Parameters: `fill_method` (default `auto_fill`), `angle`,
`row_spacing_mm`, `max_stitch_length_mm`, `staggers`, `expand_mm`. Photo
embroidery is a fill with `emb:elementType="photo_stitch"`; it behaves as a fill
in Ink/Stitch today and will gain its own `emb:` parameters later.

### Satin column

`emb:elementType="satin_column"`, a `<path>` with `inkstitch:satin_column="true"`,
stroked with the thread color and `fill="none"`. The `d` holds open subpaths:
the first two are the rails, any further subpaths are rungs. Parameters:
`zigzag_spacing_mm` (default 0.4), `pull_compensation_mm`.

## Extending the format

Two mechanisms keep the format open without a version bump:

- Unknown parameters round-trip. The reader keeps every `inkstitch:` parameter
  it does not model in the element's `params` map, and every extra `emb:`
  parameter in `customParams`. Both are written back unchanged. Adding a
  parameter means writing it; nothing in the reader or writer needs to change.
- New element types add a new `emb:elementType` value and a new element class.
  Existing types are unaffected.

## Example

A real file produced by the writer, with a fill, a satin column, and a running
outline:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg"
     xmlns:inkstitch="http://inkstitch.org/namespace"
     xmlns:emb="http://thread-digit.app/embroidery/v1"
     width="60mm" height="45mm" viewBox="0 0 60 45"
     emb:version="2.0" emb:units="mm">
  <metadata>
    <emb:design name="Sample Leaf" author="thread_digit" elementCount="3" widthMm="60" heightMm="45">
      <emb:palette>
        <emb:thread id="stem" catalog="Madeira" code="G003" name="Leaf Green" rgb="#00963C" percentage="100.0"/>
        <emb:thread id="outline" catalog="Madeira" code="R001" name="Red" rgb="#FF0000" percentage="100.0"/>
      </emb:palette>
    </emb:design>
  </metadata>
  <polygon emb:elementType="fill" emb:threadId="stem" inkstitch:fill_method="auto_fill" inkstitch:angle="40" inkstitch:row_spacing_mm="0.25" inkstitch:trim_after="true" points="15,10 45,12 40,35 12,30" stroke="none" fill="#00963C"/>
  <path emb:elementType="satin_column" emb:threadId="stem" inkstitch:zigzag_spacing_mm="0.4" inkstitch:trim_after="true" inkstitch:satin_column="true" d="M 28,12 L 26,34 M 30,12 L 28,34" fill="none" stroke="#00963C" stroke-width="0.3" stroke-linecap="round" stroke-linejoin="round"/>
  <polyline emb:elementType="line" emb:threadId="outline" inkstitch:running_stitch_length_mm="2.0" inkstitch:trim_after="true" inkstitch:stroke_method="running_stitch" points="15,10 45,12 40,35 12,30 15,10" fill="none" stroke="#FF0000" stroke-width="0.3" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
```

The same file is at `docs/examples/sample.emb.svg`.

## Ink/Stitch compatibility

The parametric elements use Ink/Stitch's namespace, parameter names, units, and
detection rules, so Ink/Stitch reads an `.emb.svg` as embroidery: lines become
running stitches, polygons become fills, satin paths become satin columns, and
manual elements keep their exact points.

What Ink/Stitch does not keep is our thread-catalog data. Ink/Stitch stores color
as plain `stroke`/`fill` and does not persist a palette in the SVG, so the
`emb:palette`, `emb:threadId`, and `emb:elementType` attributes survive a round
trip through our tools but not through Ink/Stitch. The RGB colors survive
either way. Full catalog fidelity is the reason for the `emb` namespace.
