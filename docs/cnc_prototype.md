# CNC prototype run — `may_controller` v1

First metal prototype: both halves machined from 6061 aluminium billet,
using the `may.scad` layout (160 × 132 mm with a bottom-left chamfer
from (70, 0) to (0, 56); the right half mirrors this).

## Deliverables per half

| File                          | Format | Use                                          |
| ----------------------------- | ------ | -------------------------------------------- |
| `build/may_<side>_tray.step`  | STEP   | 3D pocketed tray                             |
| `build/may_<side>_top.dxf`    | DXF    | 2D top plate layout (informational always; sufficient for machining only in `screws_from = "top"` mode) |
| `build/may_<side>_top.step`   | STEP   | 3D top plate; required for machining in `screws_from = "bottom"` mode |

`<side>` is `left` or `right`. Build all six with `make cnc` from
`enclosure/`.

## Screw direction (`screws_from`)

A top-level parameter in `may.scad` (also in `params.scad`) selects which
face the M3 screws insert from. Either mode uses the same M3 × 8 DIN 7991
flat-head screws; only the geometry placement differs.

- **`screws_from = "top"`** (default): screws come down through the top
  plate. Top plate gets clearance holes + 90° countersinks on its top
  face. Tray gets 4 integral posts standing up from the floor, tapped
  M3. The top plate is flat — **`top.dxf` is the right export to send the
  shop** (top.step is identical 3D info but DXF is what 2D shops want).
- **`screws_from = "bottom"`**: screws come up through the tray floor.
  Tray floor gets clearance holes + 90° countersinks on its bottom face.
  Top plate gets 4 pendant posts hanging from the underside, tapped M3.
  The top plate is **no longer flat** — must use **`top.step`**, since
  DXF cannot describe the pendant posts.

The button-hole layout, USB-C cutout, panel-screw row, walls, ledge, and
PCB pocket are identical between the two modes.

The STEP files are derived from OpenSCAD STLs via a FreeCAD headless bridge
(`scripts/stl_to_step.py`). The conversion is faceted, not analytic — see
"Fallback" below if the shop's CAM rejects them.

## Button layout note

The top plate is cut with **round button holes** (24 mm and 30 mm),
arcade-style. The actual switches are Kailh Choc v2 mounted on the PCB
underneath; each switch carries a custom round arcade-style keycap whose
stem plugs into the Choc v2 MX-compatible stem. The metal top plate does
not need to know anything about Choc v2 geometry.

Per-side button counts (from `lib/clusters/may_face.scad`):
- **left**: 6 × 24 mm + 1 × 30 mm (start/menu)
- **right**: 9 × 24 mm + 1 × 30 mm (start/menu)

A row of 6 small (~2.4 mm) cosmetic clearance holes at the top of each
plate is carried over from the original lfet FreeCAD design — leave them
in unless you specifically want to drop them.

## Material & finish

- **Material:** 6061-T6 aluminium, both tray and top plate.
- **Finish:** raw machined OK for prototype. Optional clear or matte-black
  anodise post-machining; subtract 0.025 mm per coated face on any
  tight-tolerance feature (none in this design).
- **Edge break:** 0.5 mm × 45° chamfer on all outer top edges of the tray
  and both faces of the top plate. Not modelled in the STEP/DXF — please
  apply per this callout.

## Tray (STEP)

- Outer XY: 160 × 132 mm with bottom-left chamfer (right half mirrored).
  Stock should be sized to that outline + fixturing allowance (shop's
  discretion).
- Pocket floor: 1.5 mm thick under the PCB.
- Posts (`screws_from = "top"` only): integral, 6.0 mm OD, four positions
  per half (three corners + one inside the chamfer at (42, 42)). Each
  post receives an M3 × 0.5 tapped hole, 2.5 mm tap-drill, depth ≥ 6 mm.
  Threads from the plate-facing top face; do not break through to the
  pocket floor.
- Floor clearance holes (`screws_from = "bottom"` only): 3.4 mm through
  the entire 1.5 mm floor at the four post positions, with a 90°
  countersink on the **bottom** face (top dia 6.4 mm, depth 1.5 mm) for
  the DIN 7991 flat-head screws.
- Inner corner radii: minimum 3.0 mm (assumes a 6 mm flat end-mill). If
  the shop's available cutter differs, update `metal_min_internal_r` in
  `params.scad` and regenerate.
- USB cutouts on the inner long edge: three notches through the inner
  wall (the long straight side that faces the other half — right edge of
  the left half, left edge of the right half). In series from the top
  edge going down: USB-C (9 mm wide), USB-C (9 mm wide), micro USB-A
  (7 mm wide), with 4 mm gaps and the first cutout 8 mm below the top
  edge. Each cutout passes through the full 2.5 mm wall thickness and
  extends in z from the top of the pocket floor (z = 1.5 mm) up to the
  top of the wall (z = 8.6 mm) — an open-top notch closed off by the
  top plate when assembled. PCB design must place the three receptacles
  so their mouths land within this z-band; see the open-issue note below.

## Top plate

- Material thickness: 1.5 mm (`metal_top_t` in `params.scad`).
- Profile: 160 × 132 mm with bottom-left chamfer (right plate mirrored).
- Always-present through-cuts:
  - Round button holes: 24 mm and 30 mm circles per the button-layout
    note above.
  - OLED window: 26 × 14 mm rectangle, centred at (130, 110) in the
    pre-mirror local frame (top-left corner of the assembled right
    controller; top-right of the left). Sized for an SSD1315 0.96"
    OLED breakout viewable area.
  - Cosmetic panel-screw row: 6 × 2.4 mm holes.
- The top plate has **no USB cutouts**; USB is in the tray wall (see Tray
  section). The top plate sits flush over the wall notches and forms
  their upper closure.

### `screws_from = "top"` (use top.dxf)

- Four extra M3 clearance holes at the corner-post positions: 3.4 mm
  dia, through the 1.5 mm plate.
- **Countersinks (NOT in the DXF — apply per callout):** at each of the
  four corner-post M3 holes on the **top** face: 90° countersink, **top
  dia 6.4 mm, depth 1.5 mm**, for M3 flat-head DIN 7991 screws.
- The plate is flat — DXF + thickness + countersink callout is complete.

### `screws_from = "bottom"` (use top.step)

- No corner clearance holes in the plate itself; the screw clearance is
  in the tray floor instead.
- Four pendant posts hang from the underside: 6.0 mm OD, ~6.9 mm long
  (post bottom hovers 0.1 mm above the tray floor when assembled). Each
  post has a blind M3 × 0.5 tapped hole opening at its bottom face, with
  2.5 mm tap-drill, depth ≥ 6 mm.
- Use `top.step` for machining — DXF can't represent the pendant posts.
  `top.dxf` is still produced as a 2D layout reference (button positions
  and outer profile).

## Screws (BOM)

| Qty | Part                                          | Notes |
| --- | --------------------------------------------- | ----- |
| 8   | M3 × 8 flat-head countersunk, DIN 7991, A2 SS | 4 per half, secures top plate to tray posts |

M3 × 6 also works if the shop reduces tap depth in the post to 4 mm.

## Verification before sending for quote

- [ ] Confirm button-hole diameters (24 mm / 30 mm) against the actual
      keycaps you intend to use, including any rim/lip allowance.
- [ ] Confirm the 26 × 14 mm OLED window matches the chosen module's
      viewable area (currently sized for a generic SSD1315 0.96" breakout).
- [ ] Confirm shop's available end-mill diameter; update
      `metal_min_internal_r` to `(tool_dia / 2) + 0.1` if not 6 mm.
- [ ] Decide whether to keep the cosmetic panel-screw row of 2.4 mm
      holes near the top edge.
- [ ] Confirm the three inner-edge USB cutout widths match the chosen
      receptacles (USB-C panel cutout typ. 9 mm; micro USB-A typ. 7 mm)
      and that the chosen receptacles' mouth centerline lands within
      z ≈ 1.5–8.6 mm relative to the tray floor.
- [ ] **Receptacle clearance vs top plate:** a typical SMT USB-C mouth
      centred ~1.5 mm above the PCB top (PCB top at z = 8.1) projects
      to z ≈ 7.85–11.35, which exceeds the wall top (z = 8.6). If the
      final PCB places the receptacles such that the mouth extends above
      the wall, the top plate will need matching edge notches — not
      designed for in this revision; catch it before quoting.
- [ ] Sanity-check that the (42, 42) post inside the chamfer doesn't
      clash with any of the button positions.
- [ ] Print one tray in PLA (with `metal_mode = true`) on the FDM
      printer; drop in an FR4 offcut and thread one screw into a post to
      confirm M3 tap-drill geometry.

## How to read the STEP + DXF pair

The STEP fully specifies the tray geometry (XY outline including chamfer,
pocket depths, post positions, tap-drill holes). Use STEP for CAM.

The DXF specifies the top plate as a 2D profile (outer outline + all
through-cuts). Plate thickness is in this document (1.5 mm); countersinks
are in this document, not the DXF.

## Fallback: faceted STEP rejected

If the shop's CAM software rejects the faceted STEP from
`scripts/stl_to_step.py`, regenerate via Fusion 360:

1. Open the corresponding `build/may_<side>_tray.stl` in Fusion 360.
2. Right-click the mesh body → **Mesh to BRep** (accept the facet-count
   warning).
3. Export the resulting solid body as STEP (`.step`).

The faceted version is preferred for the first quote because it's
reproducible from source and doesn't require a Fusion seat.

## Next steps (after prototype arrives)

- Draw the `pcb/may_left` / `pcb/may_right` KiCad outlines to match the
  pocket dimensions; place Choc v2 switches at the button positions in
  `lib/clusters/may_face.scad`.
- Source matching arcade-style round keycaps with Choc v2 stems (or
  custom-print).
- Pick anodise colour and any silkscreen / engraving.
