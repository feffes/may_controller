// Single-piece recreation of ~/dev/splitproject/lfet.FCStd.
//
// Body outline, USB cutout, and panel screws are identical between the two
// halves of the FreeCAD file. Button positions come from Sketch (Body
// "Left Top") or Sketch001 (Body001 "Right Top"), shifted by (-10, -10) so
// origin sits at the bbox bottom-left.
//
// Two switch styles supported:
//   sanwa    — 24 mm + 30 mm round holes (faithful to FreeCAD)
//   choc_v2  — same positions, but Choc v2 stepped square cutouts
//
// CLI:  openscad -o may_right_top.stl  -D 'side="right"' -D 'part="top"'  may.scad
//       openscad -o may_left_tray.stl  -D 'side="left"'  -D 'part="tray"' may.scad
// GUI:  open this file, hit F5; toggle side / part / switch_style via Customizer.

include <params.scad>
use <lib/shell.scad>
use <lib/choc_v2.scad>
use <lib/sanwa.scad>
include <lib/clusters/may_face.scad>

// [left, right]
side = "right";

// [preview, top, tray, top_dxf]
// top_dxf emits a 2D projection of the top plate for CNC DXF export.
part = "preview";

// [sanwa, choc_v2]
// Controls the *button-cap hole shape in the top plate*, not the underlying
// switch. Default "sanwa" gives circular 24 mm / 30 mm holes — the right
// thing for arcade-style round keycaps whose stems plug into Choc v2
// switches on the PCB below. "choc_v2" cuts the 13.97 mm square plate
// cutout instead, only useful if you intend to mount Choc v2 switches
// directly to the top plate (we don't, in this design).
switch_style = "sanwa";

// [top, bottom]
// Which face the M3 screws insert from. "top" → screws come down through
// the top plate into posts rising from the tray floor (corner countersinks
// visible on the top face). "bottom" → screws come up through the tray
// floor into pendant posts hanging from the underside of the top plate
// (clean top, countersinks on the tray bottom). See params.scad for the
// full semantics; this declaration mirrors it so the OpenSCAD Customizer
// picks it up when may.scad is open.
screws_from = "top";

buttons_24 = (side == "left") ? may_left_buttons_24 : may_right_buttons_24;
buttons_30 = (side == "left") ? may_left_buttons_30 : may_right_buttons_30;

// ---------- may body outline ----------
// Width 160 × height 132, bottom-left chamfer from (70, 0) up to (0, 56).
may_outline_pts = [
    [   0, 132 ],
    [ 160, 132 ],
    [ 160,   0 ],
    [  70,   0 ],
    [   0,  56 ],
];

// ---------- USB-C panel cutout (top-side rectangle) ----------
// FreeCAD: 23 × 12 at original (140-163, 116-128) → shifted (130-153, 106-118)
may_usb_origin = [130, 106];
may_usb_size   = [ 23,  12];

// ---------- screw post positions in the tray ----------
// Four positions inset from the body, accounting for the chamfer.
may_post_positions = [
    [edge_to_first_screw,        132 - edge_to_first_screw],   // top-left
    [160 - edge_to_first_screw,  132 - edge_to_first_screw],   // top-right
    [160 - edge_to_first_screw,        edge_to_first_screw],   // bottom-right
    [42, 42],                                                  // chamfer corner
];

module may_outline_2d() {
    polygon(may_outline_pts);
}

module may_button_cutout(diameter) {
    if (switch_style == "choc_v2") {
        choc_v2_full_cutout();
    } else {
        // sanwa default
        eps = 0.01;
        translate([0, 0, -eps])
            cylinder(d = diameter, h = top_thickness + 2 * eps);
    }
}

module may_top() {
    eps = 0.01;
    difference() {
        linear_extrude(top_thickness) may_outline_2d();

        // 24 mm holes
        for (xy = buttons_24)
            translate([xy.x, xy.y, 0])
                may_button_cutout(24);

        // 30 mm hole (drawn slightly larger for sanwa, same as 24mm cutout for choc)
        for (xy = buttons_30)
            translate([xy.x, xy.y, 0])
                may_button_cutout(30);

        // USB-C panel cutout
        translate([may_usb_origin.x, may_usb_origin.y, -eps])
            cube([may_usb_size.x, may_usb_size.y, top_thickness + 2 * eps]);

        // top-side panel screws (M2 free-fit, kept for FreeCAD fidelity)
        for (xy = may_top_screws)
            translate([xy.x, xy.y, -eps])
                cylinder(d = 2.4, h = top_thickness + 2 * eps);

        // corner screw clearances + top-face countersinks (only when
        // screws enter from above; with bottom-screws the top is solid here)
        if (screws_from == "top") {
            for (xy = may_post_positions) {
                translate([xy.x, xy.y, -eps])
                    cylinder(d = screw_clearance_dia, h = top_thickness + 2 * eps);
                // 90° countersink on the top face for DIN 7991 flat-head M3
                if (metal_mode)
                    translate([xy.x, xy.y, top_thickness - metal_screw_csk_depth])
                        cylinder(d1 = screw_clearance_dia,
                                 d2 = metal_screw_csk_top_d,
                                 h = metal_screw_csk_depth + eps);
            }
        }
    }

    // pendant posts hanging from the underside of the top plate, for screws
    // entering from below. Post bottom hovers 0.1 mm above the tray floor so
    // the plate clamps to the walls (not to the post bottom) when tightened.
    if (screws_from == "bottom") {
        post_height = tray_height - floor_thickness - 0.1;
        for (xy = may_post_positions)
            translate([xy.x, xy.y, -post_height])
                screw_post(post_height, tap_at = "bottom");
    }
}

// Inward polygon offset that produces millable inner corner radii.
// Composes "shrink sharp by (d + R)" + "grow rounded by R" — a morphological
// opening that yields a net inward offset of d with all corners rounded to R.
// In print mode the original sharp offset is fine and corner radius doesn't matter.
module may_cavity_2d(d) {
    if (metal_mode)
        offset(r = metal_inner_corner_r)
            offset(delta = -(d + metal_inner_corner_r))
                may_outline_2d();
    else
        offset(delta = -d) may_outline_2d();
}

module may_tray() {
    eps = 0.01;
    difference() {
        linear_extrude(tray_height) may_outline_2d();

        // lower cavity (between floor and ledge top)
        translate([0, 0, floor_thickness])
            linear_extrude(ledge_height + eps)
                may_cavity_2d(wall_thickness);

        // upper cavity (above ledge — narrower, creates the PCB ledge)
        translate([0, 0, floor_thickness + ledge_height])
            linear_extrude(tray_height - floor_thickness - ledge_height + eps)
                may_cavity_2d(wall_thickness + ledge_width);

        // floor clearance holes + bottom-face countersinks (only when
        // screws enter from below; with top-screws the floor is solid here)
        if (screws_from == "bottom") {
            for (xy = may_post_positions) {
                // through-clearance through the entire floor
                translate([xy.x, xy.y, -eps])
                    cylinder(d = screw_clearance_dia,
                             h = floor_thickness + 2 * eps);
                // 90° countersink on the bottom face (wide at z=0, narrow upward)
                if (metal_mode)
                    translate([xy.x, xy.y, -eps])
                        cylinder(d1 = metal_screw_csk_top_d,
                                 d2 = screw_clearance_dia,
                                 h = metal_screw_csk_depth + eps);
            }
        }
    }

    // floor-mounted screw posts (only when screws enter from above)
    if (screws_from == "top")
        for (xy = may_post_positions)
            translate([xy.x, xy.y, floor_thickness])
                screw_post(tray_height - floor_thickness);
}

// Right half mirrors the left around x = 160/2 so the chamfer ends up on the
// bottom-right corner — the two halves form a mirror-symmetric pair.
module flip_if_right() {
    if (side == "right")
        translate([160, 0, 0]) mirror([1, 0, 0]) children();
    else
        children();
}

if      (part == "top")     flip_if_right() may_top();
else if (part == "tray")    flip_if_right() may_tray();
else if (part == "top_dxf") projection(cut = false) flip_if_right() may_top();
else {
    flip_if_right() may_tray();
    color("DimGray", 0.6)
        translate([0, 0, tray_height + 1])
            flip_if_right() may_top();
}
