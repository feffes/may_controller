// All dimensions in mm. Single source of truth — do not hardcode numbers in
// left.scad / right.scad / lib modules; pull them from here.
//
// Items marked "TBD verify" should be confirmed against datasheets or a
// physical part before printing. See ../../research/ for sources.

// ---------- build mode ----------
// metal_mode = true  → geometry targets a CNC'd 6061 aluminium billet
//                      (pocketed tray with integral posts, flat top plate).
// metal_mode = false → geometry targets FDM 3D print with M3 heat-set inserts.
// Both share the same params; metal_mode just selects different derived
// values and branches in lib/shell.scad.
metal_mode = true;

// screws_from selects which face the M3 screws insert from:
//   "top"    → screws enter the top plate, thread into posts rising from
//              the tray floor. Top plate has clearance + countersink on its
//              top face. Tray floor is solid.
//   "bottom" → screws enter the tray floor, thread into pendant posts
//              hanging from the underside of the top plate. Top plate has
//              no visible screws. Tray floor has clearance holes +
//              countersink on its bottom face.
// Same screw spec (M3 × 8 DIN 7991 flat-head) in both modes.
screws_from = "top";

// ---------- shell construction (carry-over from lfet.FCStd) ----------
wall_thickness         = metal_mode ? 2.5 : 2;   // outer wall
floor_thickness        = metal_mode ? 1.5 : 2;   // tray bottom (billet floor under PCB)
ledge_height           = 5;     // height of inner ledge above floor; PCB rests on top
ledge_width            = 2;     // how far the ledge protrudes inward from the wall
bezel_above_plate      = 3;     // top shell extends this much above the plate (print mode)
shell_corner_radius    = 4;     // outer corner rounding
pcb_clearance          = 0.5;   // gap between PCB top and plate bottom

// ---------- screw posts (FDM, M3 with brass heat-set inserts) ----------
// Used only when metal_mode = false. Kept defined so a printed fit-check
// version still compiles.
heatset_insert_dia     = 4.0;   // TBD verify against actual part (4.0-4.7 mm common)
heatset_insert_depth   = 5.0;   // length of the brass body
heatset_hole_dia       = 3.8;   // insert OD - 0.2; insert displaces plastic into threads
heatset_hole_depth     = 6.0;   // insert depth + 1 mm relief for displaced plastic
screw_post_outer_dia   = 8.0;   // boss OD >= 2x insert OD to avoid wall blowout
screw_clearance_dia    = 3.4;   // M3 free-fit through the top shell
edge_to_first_screw    = 9;     // 8 + ~1 mm clearance from boss edge to upper-cavity wall

// ---------- metal mode (CNC 6061 aluminium billet) ----------
// M3 tapped directly into the aluminium posts; no heat-set inserts.
// Screws are M3 flat-head countersunk (DIN 7991) so the head fits flush in
// the 1.5 mm top plate. M3 SHCS heads are too tall (3 mm) for this thickness.
metal_top_t                  = 1.5;  // top plate thickness; matches Choc v2 plate window
metal_min_internal_r         = 3.0;  // inner-corner radius = (end-mill dia)/2 + 0.1; spec for a 6 mm cutter
metal_post_d                 = 6.0;  // integral post OD; M3 tap-drill leaves 1.75 mm wall in 6061
metal_m3_tap_drill           = 2.5;  // M3 × 0.5 coarse
metal_m3_tap_depth           = 6.0;  // ≥ 2×D engagement
// 90° countersink, depth 1.5 in a 1.5 mm plate. For geometric consistency
// with a 90° cone above the 3.4 mm clearance hole, top_d must equal
// clearance_dia + 2 × depth = 6.4 mm. DIN 7991 M3 head (6.0 mm) fits with
// 0.2 mm radial clearance; head sits ~0.15 mm proud of the face.
metal_screw_csk_top_d        = 6.4;
metal_screw_csk_depth        = 1.5;
metal_chamfer                = 0.5;  // outer top-edge break; spec'd in docs, not modelled
metal_inner_corner_r         = max(metal_min_internal_r, shell_corner_radius - wall_thickness);

// ---------- Kailh Choc v2 (PG1353) ----------
choc_plate_cutout      = 13.97; // square cutout for switch retention
// In metal mode, the entire 1.5 mm plate IS the snug retention zone;
// collapses the upper "body clearance" step in choc_v2_full_cutout() to ~0.
choc_plate_thickness   = metal_mode ? metal_top_t : 1.2;  // TBD verify: 1.2-1.5 mm typical
choc_snap_notch        = 0.6;   // optional side notches for snap tabs
choc_pitch_x           = 18;    // TBD pick: 18 (Choc-native) or 19 (MX)
choc_pitch_y           = 17;
choc_socket_clearance  = 1.8;   // hot-swap socket protrudes ~1.8 mm above PCB
choc_stem_above_plate  = 5.0;
choc_body_clearance    = 15;    // larger cutout above plate for switch body

// ---------- arcade-style face buttons ----------
face_button_pitch      = 24;    // classic hitbox spacing

// ---------- PCB ----------
pcb_thickness          = 1.6;
pcb_left_w             = 0;     // TBD: set after pcb/may_left outline exists
pcb_left_h             = 0;
pcb_right_w            = 0;
pcb_right_h            = 0;

// ---------- USB-C cutouts ----------
// Each half has one host USB-C and one inter-half USB-C (carrying I2C).
usb_c_cutout_w         = 9.0;   // TBD verify against chosen receptacle
usb_c_cutout_h         = 3.5;

// ---------- per-half shell outer dimensions ----------
// Used only by the (legacy) left.scad / right.scad. The current working
// design is may.scad, which uses a fixed 160×132 chamfered outline.
left_shell_size        = [110, 100];
right_shell_size       = [150, 100];

// ---------- OLED window (SSD1315 0.96" common module) ----------
oled_window_w          = 26;    // TBD verify against actual module
oled_window_h          = 14;

// ---------- layout ----------
left_cluster_buttons   = 4;
right_cluster_buttons  = 8;
has_thumb_button_left  = false;
has_thumb_button_right = false;
has_oled_left          = true;
has_oled_right         = true;

// ---------- derived ----------
tray_height = floor_thickness + ledge_height + pcb_thickness + pcb_clearance;
top_thickness = metal_mode ? metal_top_t
                           : choc_plate_thickness + bezel_above_plate;
total_height = tray_height + top_thickness;

// ---------- render quality ----------
$fa = 2;
$fs = 0.4;
