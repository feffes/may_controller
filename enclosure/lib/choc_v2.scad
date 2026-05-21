// Kailh Choc v2 (PG1353) primitives.
// Numbers come from research/choc-v2-footprint.md — verify against the
// official Kailh datasheet before manufacturing.

include <../params.scad>

// Plate cutout: 13.97 mm square with optional snap-tab notches on the
// north/south edges. Origin = bottom face of plate. Subtract from plate body.
module choc_v2_plate_cutout(plate_t = choc_plate_thickness, notches = true) {
    eps = 0.01;
    union() {
        translate([-choc_plate_cutout/2, -choc_plate_cutout/2, -eps])
            cube([choc_plate_cutout, choc_plate_cutout, plate_t + 2*eps]);

        if (notches) {
            for (sy = [-1, 1])
                translate([-2.5, sy * choc_plate_cutout/2 - eps, -eps])
                    cube([5, choc_snap_notch + 2*eps, plate_t + 2*eps]);
        }
    }
}

// Stepped cutout through the entire top shell:
//   z=0..plate_thickness        snug 13.97 sq for plate retention
//   z=plate_thickness..top      larger relief for switch body / keycap stem
// Origin = plate bottom (= bottom face of top shell).
module choc_v2_full_cutout() {
    eps = 0.01;
    choc_v2_plate_cutout();
    translate([-choc_body_clearance/2, -choc_body_clearance/2, choc_plate_thickness])
        cube([choc_body_clearance, choc_body_clearance,
              top_thickness - choc_plate_thickness + eps]);
}

// Volume to keep clear under a switch on the PCB top side, for the hot-swap
// socket. Origin = switch centre on the PCB top surface. Socket exits in -y.
module choc_v2_socket_keepout() {
    translate([-5.5, -8, 0])
        cube([11, 6, choc_socket_clearance + 0.5]);
}

// Rough envelope of an installed switch + keycap, origin = top of plate.
module choc_v2_keycap_envelope(keycap_h = 7) {
    union() {
        translate([-7.5, -7.5, 0])
            cube([15, 15, choc_stem_above_plate]);
        translate([-8.75, -8.25, choc_stem_above_plate])
            cube([17.5, 16.5, keycap_h]);
    }
}
