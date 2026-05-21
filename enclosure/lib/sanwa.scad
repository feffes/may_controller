// Round arcade-button cutouts (Sanwa OBSF-style snap-in).
// Origin = button centre. Cuts straight through the entire top shell.

include <../params.scad>

module sanwa_24_cutout() {
    eps = 0.01;
    translate([0, 0, -eps])
        cylinder(d = 24, h = top_thickness + 2 * eps);
}

module sanwa_30_cutout() {
    eps = 0.01;
    translate([0, 0, -eps])
        cylinder(d = 30, h = top_thickness + 2 * eps);
}
