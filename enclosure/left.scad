// Left half: directional cluster + OLED. Two USB-C ports — host on the back
// wall (+y), inter-half on the inboard wall (+x).
//
// CLI:  openscad -o left_top.stl  -D 'part="top"'  left.scad
//       openscad -o left_tray.stl -D 'part="tray"' left.scad
// GUI:  open this file, hit F5 (preview).

include <params.scad>
use <lib/shell.scad>
use <lib/choc_v2.scad>
use <lib/clusters/directional_4.scad>

// [preview, top, tray]
part = "preview";

size_xy        = left_shell_size;
cluster_centre = [size_xy.x / 2, size_xy.y / 2 - 10];
oled_centre    = [size_xy.x / 2, size_xy.y - 14];
host_usb_x     = size_xy.x / 2;
inter_usb_y    = size_xy.y / 2;
usb_z          = floor_thickness + ledge_height + pcb_thickness / 2;

module left_top() {
    difference() {
        shell_top_blank(size_xy);
        translate([cluster_centre.x, cluster_centre.y, 0])
            directional_4_holes();
        if (has_oled_left)
            translate([oled_centre.x, oled_centre.y, 0])
                oled_window_cutout();
    }
}

module left_tray() {
    difference() {
        shell_tray(size_xy);
        usb_c_in_pos_y_wall(size_xy, host_usb_x, usb_z);
        usb_c_in_pos_x_wall(size_xy, inter_usb_y, usb_z);
    }
}

if      (part == "top")  left_top();
else if (part == "tray") left_tray();
else {
    // preview: tray + translucent top floating slightly above
    left_tray();
    color("DimGray", 0.6)
        translate([0, 0, tray_height + 1])
            left_top();
}
