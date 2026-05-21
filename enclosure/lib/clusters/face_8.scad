// Face cluster: 8 buttons in a 4 wide x 2 tall grid at 24 mm pitch.
// Classic hitbox face layout. Origin = centre of the cluster.

include <../../params.scad>
use <../choc_v2.scad>

module face_8_holes() {
    s = face_button_pitch;
    for (col = [0:3], row = [0:1])
        translate([(col - 1.5) * s, (row - 0.5) * s, 0])
            choc_v2_full_cutout();
}
