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

// ---------- screw post positions in the tray ----------
// Four positions inset from the body, accounting for the chamfer.
may_post_positions = [
    [edge_to_first_screw,        132 - edge_to_first_screw],   // top-left
    [160 - edge_to_first_screw,  132 - edge_to_first_screw],   // top-right
    [160 - edge_to_first_screw,        edge_to_first_screw],   // bottom-right
    [42, 42],                                                  // chamfer corner
];

// Screw post: free-standing boss.
// metal_mode = true  → 6 mm OD integral post with blind M3 tap-drill hole.
// metal_mode = false → 8 mm OD printed boss with heat-set insert pocket.
// tap_at = "top"     → tapped hole opens at the post's top face (z = height).
// tap_at = "bottom"  → tapped hole opens at the post's bottom face (z = 0).
//                      Use this when the post hangs from the top plate and
//                      the screw threads up from below.
module screw_post(height, tap_at = "top") {
    eps = 0.01;
    hole_z = (tap_at == "top") ? height - metal_m3_tap_depth : -eps;
    hs_hole_z = (tap_at == "top") ? height - heatset_hole_depth : -eps;
    if (metal_mode) {
        difference() {
            cylinder(d = metal_post_d, h = height);
            translate([0, 0, hole_z])
                cylinder(d = metal_m3_tap_drill,
                         h = metal_m3_tap_depth + eps);
        }
    } else {
        difference() {
            cylinder(d = screw_post_outer_dia, h = height);
            translate([0, 0, hs_hole_z])
                cylinder(d = heatset_hole_dia,
                         h = heatset_hole_depth + eps);
        }
    }
}

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

        // OLED viewable-area window (rectangular through-cut)
        translate([oled_window_centre.x - oled_window_w/2,
                   oled_window_centre.y - oled_window_h/2,
                   -eps])
            cube([oled_window_w, oled_window_h, top_thickness + 2 * eps]);

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
    // The post passes through a Ø 6.4 mm clearance hole in the PCB; PCB
    // clamping is the press ring's job (see below), independent of this.
    if (screws_from == "bottom") {
        post_height = tray_height - floor_thickness - 0.1;
        for (xy = may_post_positions)
            translate([xy.x, xy.y, -post_height])
                screw_post(post_height, tap_at = "bottom");
    }

    // PCB press ring on plate underside — clamps PCB top down to the ledge.
    // Outer edge aligned with PCB outer edge (offset
    // wall_thickness + pcb_lateral_clearance from outline); inner edge at the
    // ledge inner edge (offset wall_thickness + ledge_width). Notched at the
    // USB cutout positions so it doesn't crash into receptacle bodies that
    // protrude inward from the wall.
    {
        eps = 0.01;
        press_height = pcb_clearance - 0.1;
        usb_widths = [usb_c_w, usb_c_w, usb_a_micro_w];
        stack_h = usb_widths[0] + usb_widths[1] + usb_widths[2]
                  + 2 * usb_inter_gap;
        top_y = usb_stack_centre_y + stack_h / 2;
        c0 = top_y - usb_widths[0] / 2;
        c1 = c0 - usb_widths[0]/2 - usb_inter_gap - usb_widths[1]/2;
        c2 = c1 - usb_widths[1]/2 - usb_inter_gap - usb_widths[2]/2;
        usb_centres = [c0, c1, c2];
        notch_clearance = 0.5;

        translate([0, 0, -press_height])
            linear_extrude(press_height)
                difference() {
                    difference() {
                        may_cavity_2d(wall_thickness + pcb_lateral_clearance);
                        may_cavity_2d(wall_thickness + ledge_width);
                    }
                    for (i = [0 : len(usb_widths) - 1])
                        translate([160 - (wall_thickness + ledge_width) - eps,
                                   usb_centres[i] - usb_widths[i]/2
                                       - notch_clearance])
                            square([wall_thickness + ledge_width + 2 * eps,
                                    usb_widths[i] + 2 * notch_clearance]);
                }
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

// USB-C panel cutout face: a stadium (rounded rectangle with semicircular
// ends), corner radius = h/2. 2D, drawn in XY with x=horizontal, y=vertical.
module usb_c_face_2d() {
    r = usb_c_h / 2;
    hull() {
        translate([+usb_c_w/2 - r, 0]) circle(r = r);
        translate([-usb_c_w/2 + r, 0]) circle(r = r);
    }
}

// Micro-USB B panel cutout face: trapezoid, wider edge up.
// 2D, drawn in XY with x=horizontal, y=vertical.
module micro_usb_face_2d() {
    w_top = usb_a_micro_w;
    w_bot = usb_a_micro_w * usb_a_micro_taper;
    h     = usb_a_micro_h;
    polygon([
        [-w_top/2, +h/2],
        [+w_top/2, +h/2],
        [+w_bot/2, -h/2],
        [-w_bot/2, -h/2],
    ]);
}

// Three USB cutouts in series on the inner long edge (x = 160 in local
// frame; the right half's flip_if_right() puts these on its left side).
// Each cutout is shaped like the actual receptacle's panel opening — USB-C
// stadium for the two USB-C ports and a trapezoid for the micro-USB port —
// extruded through the wall depth. Centred on z = PCB top + usb_centre_above_pcb.
module may_usb_wall_cutouts() {
    eps = 0.01;
    widths  = [usb_c_w, usb_c_w, usb_a_micro_w];
    is_usb_c = [true, true, false];
    stack_h = widths[0] + widths[1] + widths[2] + 2 * usb_inter_gap;
    top_y = usb_stack_centre_y + stack_h / 2;
    c0 = top_y - widths[0] / 2;
    c1 = c0 - widths[0]/2 - usb_inter_gap - widths[1]/2;
    c2 = c1 - widths[1]/2 - usb_inter_gap - widths[2]/2;
    centres = [c0, c1, c2];
    z_centre = floor_thickness + ledge_height + pcb_thickness + usb_centre_above_pcb;
    // Above the ledge top the wall is wall_thickness thick (the upper wall
    // is the narrower of the two — see may_tray for the cavity offsets).
    wall_depth = wall_thickness;

    for (i = [0 : len(widths) - 1])
        translate([160 - wall_depth - eps, centres[i], z_centre])
            // rotate([90,0,90]) is the cyclic axis permutation
            // (local X→world Y, local Y→world Z, local Z→world X), so the
            // 2D shape's horizontal becomes world Y, vertical becomes world Z,
            // and the extrusion runs along world +X through the wall.
            rotate([90, 0, 90])
                linear_extrude(height = wall_depth + 2 * eps)
                    if (is_usb_c[i]) usb_c_face_2d();
                    else             micro_usb_face_2d();
}

module may_tray() {
    eps = 0.01;
    difference() {
        linear_extrude(tray_height) may_outline_2d();

        // lower cavity (between floor and ledge top) — narrow; the thicker
        // lower wall forms a step-up ledge that the PCB rests on from above.
        translate([0, 0, floor_thickness])
            linear_extrude(ledge_height + eps)
                may_cavity_2d(wall_thickness + ledge_width);

        // upper cavity (above ledge — wide, PCB drops in through this opening)
        translate([0, 0, floor_thickness + ledge_height])
            linear_extrude(tray_height - floor_thickness - ledge_height + eps)
                may_cavity_2d(wall_thickness);

        // USB cutouts through the inner long edge
        may_usb_wall_cutouts();

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
        translate([0, 0, tray_height])
            flip_if_right() may_top();
}
