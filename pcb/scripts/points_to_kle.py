#!/usr/bin/env python3
"""Convert the ergogen points.yaml into a per-half KLE layout for kbplacer.

Why this exists
---------------
ergogen's `points.yaml` holds BOTH halves' switches plus non-switch anchors
(post_/pivot_/usb_/org_/ctr_). kbplacer needs ONE half's switch layout, and its
`kle_serial` parser divides each point's position by `meta.spread` / `meta.padding`
to normalise to key units. Our ergogen config deliberately uses `spread/padding = 0`
(so the enclosure DXF gets absolute, irregular button positions), which would make
kle_serial divide by zero.

So this script:
  1. keeps only one half's SWITCH points (face buttons `lf_`/`rf_` + the shared aux
     row `aux_`), dropping the geometric anchors;
  2. sets `spread = padding = 1` on each, so kle_serial yields KLE units in
     millimetres (1 KLE unit == 1 mm). Place with `kbplacer --key-distance 1 1`,
     which then reproduces the exact ergogen geometry.

kle_serial handles the rest (ergogen y-up -> KLE y-down flip, key-centre -> corner),
and kbplacer's placement inverts it, so relative geometry round-trips exactly.
Absolute alignment to the enclosure frame is set at placement time via
`--layout-offset` (see pcb/WORKFLOW.md).

Usage:
  points_to_kle.py --points <points.yaml> --side left|right --out <kle.json>
"""
from __future__ import annotations

import argparse
import sys

import yaml
from kbplacer.kle_serial import parse_ergogen_points

# switch points per half: this half's face buttons + the shared aux/function row.
# everything else in points.yaml (post_/pivot_/usb_/org_/ctr_) is geometry, not keys.
INCLUDE_PREFIXES = {
    "left": ("lf_", "aux_"),
    "right": ("rf_", "aux_"),
}


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--points", required=True, help="ergogen output/points/points.yaml")
    ap.add_argument("--side", required=True, choices=["left", "right"])
    ap.add_argument("--out", required=True, help="destination KLE (internal) json")
    args = ap.parse_args()

    with open(args.points, encoding="utf-8") as f:
        points = yaml.safe_load(f)

    prefixes = INCLUDE_PREFIXES[args.side]
    filtered: dict = {}
    for name, item in points.items():
        if not name.startswith(prefixes):
            continue
        item = dict(item)
        item["meta"] = dict(item["meta"])
        item["meta"]["spread"] = 1  # KLE unit == 1 mm  (use kbplacer --key-distance 1 1)
        item["meta"]["padding"] = 1
        filtered[name] = item

    if not filtered:
        sys.exit(f"points_to_kle: no switch points matched side={args.side}")

    keyboard = parse_ergogen_points(filtered)
    with open(args.out, "w", encoding="utf-8") as f:
        f.write(keyboard.to_json(indent=2))
    print(f"{args.side}: {len(keyboard.keys)} keys -> {args.out}")


if __name__ == "__main__":
    main()
