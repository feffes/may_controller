OPENSCAD ?= openscad
FREECADCMD ?= freecadcmd
BUILD := build

DEPS := \
	params.scad \
	lib/shell.scad \
	lib/choc_v2.scad \
	lib/sanwa.scad \
	lib/clusters/directional_4.scad \
	lib/clusters/face_8.scad \
	lib/clusters/may_face.scad

STLS := \
	$(BUILD)/left_top.stl \
	$(BUILD)/left_tray.stl \
	$(BUILD)/right_top.stl \
	$(BUILD)/right_tray.stl \
	$(BUILD)/may_left_top.stl \
	$(BUILD)/may_left_tray.stl \
	$(BUILD)/may_right_top.stl \
	$(BUILD)/may_right_tray.stl

all: $(STLS)

$(BUILD):
	mkdir -p $@

$(BUILD)/left_top.stl: left.scad $(DEPS) | $(BUILD)
	$(OPENSCAD) -o $@ -D 'part="top"' $<

$(BUILD)/left_tray.stl: left.scad $(DEPS) | $(BUILD)
	$(OPENSCAD) -o $@ -D 'part="tray"' $<

$(BUILD)/right_top.stl: right.scad $(DEPS) | $(BUILD)
	$(OPENSCAD) -o $@ -D 'part="top"' $<

$(BUILD)/right_tray.stl: right.scad $(DEPS) | $(BUILD)
	$(OPENSCAD) -o $@ -D 'part="tray"' $<

$(BUILD)/may_left_top.stl: may.scad $(DEPS) | $(BUILD)
	$(OPENSCAD) -o $@ -D 'side="left"' -D 'part="top"' $<

$(BUILD)/may_left_tray.stl: may.scad $(DEPS) | $(BUILD)
	$(OPENSCAD) -o $@ -D 'side="left"' -D 'part="tray"' $<

$(BUILD)/may_right_top.stl: may.scad $(DEPS) | $(BUILD)
	$(OPENSCAD) -o $@ -D 'side="right"' -D 'part="top"' $<

$(BUILD)/may_right_tray.stl: may.scad $(DEPS) | $(BUILD)
	$(OPENSCAD) -o $@ -D 'side="right"' -D 'part="tray"' $<

# Quick PNG previews (handy for terminal-only inspection)
preview: $(BUILD)/left_preview.png $(BUILD)/right_preview.png $(BUILD)/may_preview.png

$(BUILD)/left_preview.png: left.scad $(DEPS) | $(BUILD)
	$(OPENSCAD) -o $@ --imgsize=1200,900 --colorscheme=Tomorrow $<

$(BUILD)/right_preview.png: right.scad $(DEPS) | $(BUILD)
	$(OPENSCAD) -o $@ --imgsize=1200,900 --colorscheme=Tomorrow $<

$(BUILD)/may_preview.png: may.scad $(DEPS) | $(BUILD)
	$(OPENSCAD) -o $@ --imgsize=1400,1000 --colorscheme=Tomorrow $<

# ---------- CNC artefacts (metal_mode = true) ----------
# Trays go through a FreeCAD STL→STEP bridge because OpenSCAD's native STEP
# export is unusable. Tops project to DXF directly via the `part=top_dxf`
# dispatch in may.scad.

CNC := \
	$(BUILD)/may_left_tray.step  \
	$(BUILD)/may_left_top.dxf    \
	$(BUILD)/may_left_top.step   \
	$(BUILD)/may_right_tray.step \
	$(BUILD)/may_right_top.dxf   \
	$(BUILD)/may_right_top.step

cnc: $(CNC)

# Trays and tops both get STEP via the FreeCAD bridge; pattern rule covers both.
$(BUILD)/%.step: $(BUILD)/%.stl scripts/stl_to_step.py | $(BUILD)
	$(FREECADCMD) scripts/stl_to_step.py -- $< $@

# Top DXF is the right export for screws_from = "top" (flat plate).
# For screws_from = "bottom" the top has pendant posts and isn't 2D —
# use the top.step instead. The DXF is still informative as a 2D layout.
$(BUILD)/may_left_top.dxf: may.scad $(DEPS) | $(BUILD)
	$(OPENSCAD) -o $@ -D 'side="left"' -D 'part="top_dxf"' $<

$(BUILD)/may_right_top.dxf: may.scad $(DEPS) | $(BUILD)
	$(OPENSCAD) -o $@ -D 'side="right"' -D 'part="top_dxf"' $<

clean:
	rm -rf $(BUILD)

.PHONY: all preview cnc clean
