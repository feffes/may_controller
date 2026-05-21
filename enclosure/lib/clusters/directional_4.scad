// Directional cluster: 4 buttons in a "+" pattern at 24 mm pitch.
// Placeholder layout. Refine to a proper hitbox-style directional (3 in a
// row + 1 thumb) once the actual button mapping is decided.
//
// Origin = centre of the cluster. Cuts go through the entire top shell
// from z=0 (plate bottom) upward.

include <../../params.scad>
use <../choc_v2.scad>

module directional_4_holes() {
    s = face_button_pitch;
    for (pos = [[0, s], [s, 0], [0, -s], [-s, 0]])
        translate([pos.x, pos.y, 0])
            choc_v2_full_cutout();
}
