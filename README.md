# may_controller

Split-layout flatbox-style game controller. Two physical halves, Kailh Choc v2 switches, RP2350.

Project context, conventions, and open decisions live in the parent research hub at [`../CLAUDE.md`](../CLAUDE.md) and [`../research/`](../research/) — this repo is the deliverable.

## Layout

```
enclosure/      OpenSCAD models of both halves (top shell + bottom tray)
  params.scad   single source of truth for all dimensions
  lib/          reusable modules (choc_v2 cutout, mount boss, ...)
pcb/
  may_left/     KiCad 9 project, left half
  may_right/    KiCad 9 project, right half
firmware/       framework TBD (GP2040-CE / QMK / KMK / Pico-SDK)
docs/           assembly + BOM
```

## Building the enclosure

```sh
cd enclosure
openscad -o left_top.stl  left.scad   -D 'part="top"'
openscad -o left_tray.stl left.scad   -D 'part="tray"'
openscad -o right_top.stl right.scad  -D 'part="top"'
openscad -o right_tray.stl right.scad -D 'part="tray"'
```

A `Makefile` will replace this once the body files exist.
