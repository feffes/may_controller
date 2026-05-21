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

// ---------- OLED window (SSD1315 0.96" common module) ----------
// Through-cut in the top plate. Centre is in may.scad's local pre-mirror
// frame — same position on both halves, so the mirror puts the window
// in the top-left of the right controller and the top-right of the left,
// each facing outward toward its hand.
oled_window_w          = 26;            // TBD verify against actual module
oled_window_h          = 14;
oled_window_centre     = [130, 110];

// ---------- USB cutouts (inner edge of each half) ----------
// Two USB-C (host + inter-half I2C link) and one micro USB-A in series,
// top-aligned on the inner long edge (x = 160 in may.scad local frame).
// Each cutout is a notch through the full wall thickness (in x) running
// from z = floor_thickness up to z = tray_height — open at the top of
// the wall so the receptacle's mouth elevation has some latitude until
// the PCB outline is drawn.
usb_c_w                = 9.0;   // panel cutout width along y (TBD verify)
usb_a_micro_w          = 7.0;   // micro USB-A panel cutout width along y
usb_top_edge_margin    = 8.0;   // y from top edge (132) to first cutout
usb_inter_gap          = 4.0;   // gap between adjacent cutouts

// ---------- derived ----------
tray_height = floor_thickness + ledge_height + pcb_thickness + pcb_clearance;
top_thickness = metal_mode ? metal_top_t
                           : choc_plate_thickness + bezel_above_plate;
total_height = tray_height + top_thickness;

// ---------- render quality ----------
$fa = 2;
$fs = 0.4;
