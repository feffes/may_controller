// Button positions transcribed verbatim from /home/feffe/dev/splitproject/lfet.FCStd,
// normalised so each body's bounding-box bottom-left corner is at (0, 0)
// (original FreeCAD coords had a (10, 10) base offset).
//
// Right top  → Sketch001 / Body001 ("Right Top"):
//   9 × 24 mm Sanwa face/thumb buttons (4×2 staggered grid + 1 thumb)
//   1 × 30 mm Sanwa start/menu button
//
// Left top   → Sketch    / Body    ("Left Top"):
//   6 × 24 mm Sanwa buttons (4-button staggered row + 1 above + 1 thumb)
//   1 × 30 mm Sanwa start/menu button
//
// Body outline, USB cutout, and panel-screw row are identical between halves —
// only the button cluster changes.

// ---------- right top ----------
may_right_buttons_24 = [
    [ 21.275,  63.5  ],   // index   col, top
    [ 21.275,  92.5  ],   // index   col, bottom
    [ 50.170,  66    ],   // middle  col, top
    [ 50.170,  95    ],   // middle  col, bottom
    [ 79.170,  66    ],   // ring    col, top
    [ 79.170,  95    ],   // ring    col, bottom
    [106.000,  55    ],   // pinky   col, top
    [106.000,  84    ],   // pinky   col, bottom
    [ 90.600,  31    ],   // lower thumb / select-style
];

may_right_buttons_30 = [
    [121, 21],            // start / menu
];

// ---------- left top ----------
may_left_buttons_24 = [
    [ 23.898,  76.568 ],  // 4-button staggered row (far left)
    [ 51.119,  86.568 ],
    [ 80.077,  85.000 ],
    [106.000,  72.000 ],  // 4-button staggered row (right end)
    [ 87.518, 113.029 ],  // upper button above the row
    [ 90.603,  31.000 ],  // lower thumb
];

may_left_buttons_30 = [
    [121, 21],            // start / menu
];

// ---------- shared: top-side panel screws ----------
// 7.5 mm round (FreeCAD Sketch / Sketch001 ids 22-27). Probably for a sub-panel
// or accessory mount in the may design — kept as cosmetic clearance holes for
// fidelity.
may_top_screws = [
    [12, 120], [22, 120], [32, 120], [42, 120], [52, 120], [62, 120],
];
