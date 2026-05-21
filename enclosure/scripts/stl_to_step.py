"""STL → STEP converter using FreeCAD headless.

Usage (called from Makefile):
    freecadcmd stl_to_step.py -- input.stl output.step

The mesh-to-shape conversion is lossy: pockets become faceted polyhedra,
not analytic surfaces. Acceptable for first-prototype quoting because the
pockets in this design are box-shaped — the shop can re-derive arcs from
the DXF and pocket depths from the callout in docs/cnc_prototype.md.

If the shop's CAM rejects the faceted STEP at quote stage, use the Fusion
360 fallback documented in docs/cnc_prototype.md (Mesh → BRep → STEP).
"""

import sys

import FreeCAD  # noqa: F401  -- provided by FreeCAD runtime
import Mesh  # noqa: F401  -- provided by FreeCAD runtime
import Part  # noqa: F401  -- provided by FreeCAD runtime


def main() -> None:
    # freecadcmd passes user args after a "--" separator. Be tolerant if it's omitted.
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    if len(args) != 2:
        sys.stderr.write("usage: freecadcmd stl_to_step.py -- input.stl output.step\n")
        sys.exit(2)

    input_stl, output_step = args

    # Part.export() needs Document Objects (with a .Shape attribute), not raw
    # TopoShape — so we stage through a document.
    doc = FreeCAD.newDocument("step_export")
    mesh = Mesh.Mesh(input_stl)
    shape = Part.Shape()
    shape.makeShapeFromMesh(mesh.Topology, 0.05)  # 0.05 mm sewing tolerance
    obj = doc.addObject("Part::Feature", "tray")
    obj.Shape = shape
    doc.recompute()
    Part.export([obj], output_step)


main()
