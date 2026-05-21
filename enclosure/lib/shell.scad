// Base shell primitives: tray (bottom + walls + ledge + posts) and top blank
// (bezel + plate, no holes). Caller composes cluster cutouts and OLED.
//
// Coordinate convention: tray spans [0, size.x] x [0, size.y] x [0, tray_height].
// Top shell spans [0, size.x] x [0, size.y] x [0, top_thickness] in its own
// local frame; place it at z = tray_height for assembled previews.
//
// metal_mode (set in params.scad) switches between FDM-print geometry
// (printed posts with heat-set inserts, bezel above plate) and CNC'd 6061
// billet geometry (integral posts with M3 tapped holes, flat 1.5 mm top
// plate with countersinks). Inner corner radii clamp to metal_min_internal_r
// in metal mode so the geometry is millable with the spec'd cutter.

include <../params.scad>

// ----- 2D rounded rectangle, origin at (0,0) corner -----
module rounded_rect_2d(size_xy, radius) {
    hull() {
        for (x = [radius, size_xy.x - radius],
             y = [radius, size_xy.y - radius])
            translate([x, y]) circle(r = radius);
    }
}

module rounded_box(size_xyz, radius) {
    linear_extrude(size_xyz.z)
        rounded_rect_2d([size_xyz.x, size_xyz.y], radius);
}

// ----- screw post: free-standing boss -----
// metal_mode = true  → 6 mm OD integral post with blind M3 tap-drill hole.
// metal_mode = false → 8 mm OD printed boss with heat-set insert pocket.
// tap_at = "top"     → tapped hole opens at the post's top face (z = height).
// tap_at = "bottom"  → tapped hole opens at the post's bottom face (z = 0).
//                      Use this when the post hangs from a top plate and the
//                      screw threads up from below.
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

// ----- 4 corner positions inset from edges -----
function corner_positions(size_xy, inset) = [
    [inset,             inset],
    [size_xy.x - inset, inset],
    [inset,             size_xy.y - inset],
    [size_xy.x - inset, size_xy.y - inset],
];

// ----- the tray: floor + walls + interior ledge + 4 corner screw posts -----
// Same stepped-pocket geometry in both modes; in metal mode the inner
// corner radii clamp to metal_min_internal_r so the cavity is millable.
module shell_tray(size_xy) {
    eps = 0.01;
    inner_corner_lower = metal_mode
        ? max(metal_min_internal_r, shell_corner_radius - wall_thickness)
        : max(shell_corner_radius - wall_thickness, 1);
    inner_corner_upper = metal_mode
        ? metal_min_internal_r
        : max(inner_corner_lower - ledge_width, 0.5);

    difference() {
        // outer body
        rounded_box([size_xy.x, size_xy.y, tray_height], shell_corner_radius);

        // lower cavity (between floor and ledge top): full interior minus walls
        translate([wall_thickness, wall_thickness, floor_thickness])
            rounded_box([size_xy.x - 2*wall_thickness,
                         size_xy.y - 2*wall_thickness,
                         ledge_height + eps],
                        inner_corner_lower);

        // upper cavity (above ledge): narrower by ledge_width on each side,
        // creates the lip that supports the PCB
        translate([wall_thickness + ledge_width,
                   wall_thickness + ledge_width,
                   floor_thickness + ledge_height])
            rounded_box([size_xy.x - 2*(wall_thickness + ledge_width),
                         size_xy.y - 2*(wall_thickness + ledge_width),
                         tray_height - floor_thickness - ledge_height + eps],
                        inner_corner_upper);
    }

    // four corner screw posts on the floor
    for (xy = corner_positions(size_xy, edge_to_first_screw))
        translate([xy.x, xy.y, floor_thickness])
            screw_post(tray_height - floor_thickness);
}

// ----- top blank: solid plate with screw holes -----
// metal_mode = true  → flat metal_top_t plate, M3 through + 90° countersink
//                      for DIN 7991 flat-head screws (head sits flush).
// metal_mode = false → bezel + plate with simple M3 clearance through-holes.
module shell_top_blank(size_xy) {
    eps = 0.01;
    if (metal_mode) {
        difference() {
            rounded_box([size_xy.x, size_xy.y, metal_top_t], shell_corner_radius);
            for (xy = corner_positions(size_xy, edge_to_first_screw)) {
                translate([xy.x, xy.y, -eps])
                    cylinder(d = screw_clearance_dia,
                             h = metal_top_t + 2*eps);
                // 90° countersink opening upward
                translate([xy.x, xy.y,
                           metal_top_t - metal_screw_csk_depth])
                    cylinder(d1 = screw_clearance_dia,
                             d2 = metal_screw_csk_top_d,
                             h = metal_screw_csk_depth + eps);
            }
        }
    } else {
        difference() {
            rounded_box([size_xy.x, size_xy.y, top_thickness], shell_corner_radius);
            for (xy = corner_positions(size_xy, edge_to_first_screw))
                translate([xy.x, xy.y, -eps])
                    cylinder(d = screw_clearance_dia,
                             h = top_thickness + 2*eps);
        }
    }
}

// ----- OLED rectangular window (cuts through the entire top) -----
//   Origin = window centre.
module oled_window_cutout() {
    eps = 0.01;
    translate([-oled_window_w/2, -oled_window_h/2, -eps])
        cube([oled_window_w, oled_window_h, top_thickness + 2*eps]);
}

// ----- USB-C cutouts in tray walls (centred on the cutout's xy) -----
// Place at z = z_centre (mid-PCB height is sensible). Caller picks the wall.
module usb_c_in_pos_y_wall(size_xy, at_x, at_z) {
    eps = 0.01;
    translate([at_x - usb_c_cutout_w/2,
               size_xy.y - wall_thickness - eps,
               at_z - usb_c_cutout_h/2])
        cube([usb_c_cutout_w, wall_thickness + 2*eps, usb_c_cutout_h]);
}

module usb_c_in_neg_y_wall(at_x, at_z) {
    eps = 0.01;
    translate([at_x - usb_c_cutout_w/2,
               -eps,
               at_z - usb_c_cutout_h/2])
        cube([usb_c_cutout_w, wall_thickness + 2*eps, usb_c_cutout_h]);
}

module usb_c_in_pos_x_wall(size_xy, at_y, at_z) {
    eps = 0.01;
    translate([size_xy.x - wall_thickness - eps,
               at_y - usb_c_cutout_w/2,
               at_z - usb_c_cutout_h/2])
        cube([wall_thickness + 2*eps, usb_c_cutout_w, usb_c_cutout_h]);
}

module usb_c_in_neg_x_wall(at_y, at_z) {
    eps = 0.01;
    translate([-eps,
               at_y - usb_c_cutout_w/2,
               at_z - usb_c_cutout_h/2])
        cube([wall_thickness + 2*eps, usb_c_cutout_w, usb_c_cutout_h]);
}
