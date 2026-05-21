// Right half: 8-button face cluster + OLED. Two USB-C ports — host on the
// back wall (+y), inter-half on the inboard wall (-x).
//
// CLI:  openscad -o right_top.stl  -D 'part="top"'  right.scad
//       openscad -o right_tray.stl -D 'part="tray"' right.scad
// GUI:  open this file, hit F5 (preview).

include <params.scad>
use <lib/shell.scad>
use <lib/choc_v2.scad>
use <lib/clusters/face_8.scad>

// [preview, top, tray]
part = "preview";

size_xy        = right_shell_size;
cluster_centre = [size_xy.x / 2, size_xy.y / 2 - 5];
oled_centre    = [size_xy.x / 2, size_xy.y - 18];
host_usb_x     = size_xy.x / 2;
inter_usb_y    = size_xy.y / 2;
usb_z          = floor_thickness + ledge_height + pcb_thickness / 2;

module right_top() {
    difference() {
        shell_top_blank(size_xy);
        translate([cluster_centre.x, cluster_centre.y, 0])
            face_8_holes();
        if (has_oled_right)
            translate([oled_centre.x, oled_centre.y, 0])
                oled_window_cutout();
    }
}

module right_tray() {
    difference() {
        shell_tray(size_xy);
        usb_c_in_pos_y_wall(size_xy, host_usb_x, usb_z);
        usb_c_in_neg_x_wall(inter_usb_y, usb_z);
    }
}

if      (part == "top")  right_top();
else if (part == "tray") right_tray();
else {
    right_tray();
    color("DimGray", 0.6)
        translate([0, 0, tray_height + 1])
            right_top();
}
