# may_controller PCB workflow

Two half-boards — `may_left/` and `may_right/` — share switch positions with the
enclosure by reusing the **ergogen layout as the single source of truth**. ergogen
emits key positions; **kbplacer** drops the footprints onto the board at those
positions; the **KiCad schematic owns all the nets** (RP2350, OLED, USB, the switch
matrix). Nothing is re-typed: edit `../ergogen/config.yaml` and the positions flow
to both the case and the PCB.

```
ergogen/config.yaml ──► points.yaml ──(just kle)──► pcb/build/kle_{left,right}.json
                    └──► outline_body[_right].dxf ──► KiCad Edge.Cuts
KiCad schematic  ──► netlist ──► PCB ──(kbplacer + kle_*.json)──► placed + routed matrix
```

## 0. One-time setup

```sh
cd pcb
just setup          # creates .venv with kbplacer + PyYAML (system pip is PEP-668 locked)
```

The Choc v2 hotswap footprint is vendored in `pcb/lib/Kailh_PG1353_Hotswap.pretty/`
(`Kailh-PG1353-Hotswap-1U`, from ai03-2725/MX_V2, MIT). Each project's
`fp-lib-table` already points at it via `${KIPRJMOD}/../lib`.

## 1. Generate the per-half layouts

```sh
cd pcb
just kle            # -> build/kle_left.json (13 keys), build/kle_right.json (16 keys)
```

`kle_left` = 6×24 mm + 1×30 mm face buttons + 6 aux; `kle_right` = 9 + 1 + 6.
**1 KLE unit == 1 mm** (the converter sets ergogen spread/padding to 1), so kbplacer
must be run with `--key-distance 1 1` to reproduce the exact ergogen geometry.

## 2. Schematic (manual, KiCad GUI) — the netlist source of truth

For each half (`may_left/`, `may_right/`):

1. Create the KiCad project here (`File ▸ New Project ▸ may_left.kicad_pro`). The
   existing `fp-lib-table` is picked up automatically.
2. Author the schematic — partition `~/dev/splitproject/kontroll/Flatbox-rev8.kicad_sch`
   into this half: that half's switch matrix (face + aux) **plus** its RP2350,
   OLED, and the USB connectors it carries. Reuse the kontroll symbols/nets.
3. Switch + diode + aux symbols:
   - face buttons → assign footprint `Kailh_PG1353_Hotswap:Kailh-PG1353-Hotswap-1U`
     (`Tools ▸ Assign Footprints`). **Not** the kontroll PG1350 (Choc v1) — v2 pins
     differ. See [[research/choc-v2-footprint]].
   - aux buttons → `Button_Switch_THT:SW_PUSH_6mm_H5mm` (6×6×9.5 mm THT tactiles).
   - per-key diodes → a stock `Diode_SMD` (e.g. `D_SOD-123`).
4. Reference designators: name switches so they map cleanly to the KLE order
   (kbplacer matches by annotation). Annotate consistently per half.

## 3. PCB: import netlist, then place + route with kbplacer

1. Open the PCB editor, `File ▸ Update PCB from Schematic` (footprints land in a pile).
2. Run **kbplacer** (Tools ▸ External Plugins ▸ *Keyboard footprints placer*, or CLI):
   - Layout file: `build/kle_<side>.json`.
   - **Key distance: `1 × 1` mm** (because 1 KLE unit == 1 mm here).
   - Enable *relative-position diode* to clone the switch↔diode pairing, and
     *automatic routing* for the matrix.
   - To pin the cluster to the enclosure's absolute frame, set kbplacer's
     **layout offset** so the reference key lands at its ergogen mm position;
     otherwise place freely and align to the imported Edge.Cuts (next step).
   CLI equivalent (placement needs KiCad's `pcbnew`; the GUI plugin is the reliable
   path here — system-python `pcbnew` threw an assert):
   ```sh
   python -m kbplacer -b may_<side>.kicad_pcb -l build/kle_<side>.json --key-distance 1 1 ...
   ```
3. Aux buttons / MCU / USB / OLED: place by hand (kbplacer leaves non-switch parts
   alone; it can use already-placed switches as routing references).

## 4. Board outline (Edge.Cuts)

Import the ergogen outline as the board edge:

- **may_left** → `../ergogen/output/outlines/outline_body.dxf` (chamfer bottom-left).
- **may_right** → `../ergogen/output/outlines/outline_body_right.dxf` (pre-mirrored,
  chamfer bottom-right — matches the mirrored right enclosure half).

`File ▸ Import ▸ Graphics`, target layer **Edge.Cuts**, scale 1.0, origin (0,0).
The PCB and the enclosure now share one coordinate frame, so the switch holes in
the top plate line up with the switches on the board.

## 5. Mounting holes / pivot keep-out / USB
- Mounting holes: 5 posts at the `post_*` points (`anchor_posts.dxf` for reference).
- Central pivot keep-out: 16 mm Ø at `pivot_*` (`anchor_pivot.dxf`); no copper there.
- USB connectors: along the inner edge x=160 at the `usb_*` y-centres (~88.5/72.5/54.5).
These stay manual in KiCad — ergogen emits them only as position references.

## Regenerating after a layout change
Edit `../ergogen/config.yaml`, then `just kle` again and re-run kbplacer. The
enclosure picks the same change up automatically (`cd ../enclosure && just all`).
