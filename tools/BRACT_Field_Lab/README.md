# BRACT FIELD LAB

**A geometry-first lettermark design instrument for Processing 4.**

BRACT Field Lab is not meant to be a “glitch filter.” Its first job is to help you start with a real font glyph, pull the actual outline into editable geometry, push that geometry through controlled mathematical fields, protect important anatomy, hand-sculpt the result, and export a new vector lettermark.

The BRACT `B` is the first use case. The code is intentionally generic enough to load other glyphs, short wordmarks, and other fonts later.

---

## 1. What the tool currently does

### Source
- Loads local `.ttf` and `.otf` font files.
- Uses Java's font outline engine rather than screenshotting text.
- Accepts a glyph or short string (up to 8 code points in the UI).
- Converts curves to a dense editable contour using a configurable **Outline Detail** value.

### Manual form design
- **Sculpt mode** lets you brush-push the contour like soft clay.
- **Shift-drag in Sculpt** smooths nearby manual offsets.
- **Alt/right-drag in Sculpt** relaxes the form toward the original font.
- **Node mode** exposes the sampled vector points for precise edits.
- **Reset Form** removes hand edits without deleting your effect stack.

### Geometry field stack
Fields are non-destructive and order-dependent:
- **Wave Field** — localized sine-wave displacement.
- **Slice Signal** — horizontal band / transmission behavior.
- **Point Lens** — local radial push/pull.
- **Vortex** — localized rotation field.
- **Noise Warp** — organic procedural deformation.
- **Local Shear** — focused directional slant.
- **Radial Ripple** — concentric disturbance.

Each field can be enabled, disabled, reordered, deleted, masked, and independently tuned.

### Recognition protection
- **Stem Lock** protects the left-hand structural zone.
- **Stem Width** controls how much of the left side is treated as the stem.
- **Counter Lock** protects hole contours such as the two counters of a `B`.
- **Max Travel** caps procedural displacement so experiments cannot accidentally teleport points miles away from the mark.

### Per-field paint masks
- White = effect allowed.
- Black = protected.
- Paint directly on the letter.
- Alt/right-drag erases field influence.
- Brush size can be changed with the mouse wheel.

### Non-destructive raster auditioning
The vector master remains intact while you audition:
- Bayer ordered dithering.
- Atkinson error-diffusion dithering.
- Threshold.
- Scanline cuts.
- Grain.

### Design workflow features
- Undo / redo history.
- Six in-memory variant slots.
- JSON preset save/load.
- Controlled randomization of the active field.
- Optional field animation for discovering interesting states.
- SVG vector export.
- High-resolution PNG export.

---

# 2. Install Processing and run it

## Step A — Install Processing 4

This build targets **Processing 4.5.6** (the current official release as of August 2026) and should remain compatible with nearby Processing 4.x releases.

1. Download the current Processing 4 desktop application from the official Processing website.
2. Install or unzip it normally for Windows, macOS, or Linux.
3. Launch Processing.
4. Make sure the editor says **Java** mode in the upper-right mode selector.

No third-party Processing libraries are required by this project.

## Step B — Keep the folder structure intact

Processing expects the main sketch file to live in a folder with the same name.

Keep this exactly like this:

```text
BRACT_Field_Lab/
├── BRACT_Field_Lab.pde
├── AppModel.pde
├── EditorUI.pde
├── Fields.pde
├── GlyphDocument.pde
├── HistoryVariants.pde
├── PaintMask.pde
├── RasterFX.pde
├── README.md
├── START_HERE.md
├── docs/
└── data/
```

## Step C — Open

Double-click:

```text
BRACT_Field_Lab.pde
```

or use **File → Open** inside Processing.

Processing will show the other `.pde` files as tabs automatically.

## Step D — Run

Press the triangle **Run** button.

The first launch uses the operating system's generic `Serif` font so the program is usable immediately.

Press **LOAD FONT** or keyboard shortcut **F** and choose a `.ttf` or `.otf` file when you are ready to use a real design source.

---

# 3. Your first BRACT session

Do this before trying to understand every knob.

1. Run the sketch.
2. Load a font with a `B` you find structurally interesting.
3. Leave the glyph as `B`.
4. Disable **Slice Signal** by clicking its dot/row toggle.
5. Select **Wave Field**.
6. Change only:
   - Amplitude
   - Frequency
   - Focus Y
   - Spread
7. Turn **MASK** on.
8. Paint black/protected areas over geometry you refuse to lose.
9. Turn **SCULPT** on.
10. Push the upper and lower bowls manually until the letter stops feeling like “font + effect” and starts feeling like a mark.
11. Turn **NODES** on for small surgical corrections.
12. Capture variants by **Shift-clicking V1–V6**.
13. Compare by clicking the variant buttons.
14. Export SVG when the *form* works.
15. Only then turn Raster Preview on and audition dither/scan treatments.

The philosophy is: **form first; treatment second.**

---

# 4. Controls / shortcuts

| Input | Action |
|---|---|
| `F` | Load font |
| `S` | Toggle Sculpt mode |
| Hold `Space` | Temporarily bypass procedural fields and inspect the hand-edited master |
| `N` | Toggle Node mode |
| `M` | Toggle Mask paint mode |
| `R` | Controlled randomize active field |
| `A` | Toggle animation |
| `P` | Save preset JSON |
| `L` | Load preset JSON |
| `Z` | Undo |
| `Y` | Redo |
| `1–6` | Recall variant slot |
| Shift-click `V1–V6` | Capture current state into variant slot |
| Delete / Backspace | Delete active field when not editing glyph text |
| Drag field crosshair | Move fields that have X/Y centers |
| Shift-drag artwork | Move a field's Focus Y if supported |
| Mouse wheel in Mask/Sculpt | Change brush radius |
| Alt/right-drag in Mask | Protect / erase influence |
| Shift-drag in Sculpt | Smooth nearby manual edits |
| Alt/right-drag in Sculpt | Relax manual edits toward original font |

---

# 5. ELI5: how it works

Imagine printing a `B` on a rubber sheet.

A cheap effect tool photographs the sheet, smears the photo, and gives you a new photo.

BRACT Field Lab instead asks the font:

> “Where is the actual edge of this B?”

Java returns the outline. The program walks around that outline and takes lots of tiny samples. Those become editable vector points.

Each point remembers three positions:

1. **Base** — where the font originally placed it.
2. **Manual** — how far *you* moved it with Sculpt or Nodes.
3. **Pos** — where the procedural effect stack finally moved it for the current render.

So the rough equation is:

```text
FONT SHAPE
    + YOUR HAND EDITS
    + FIELD 1
    + FIELD 2
    + FIELD 3 ...
    = CURRENT LETTERMARK
```

Nothing in the raster-preview section changes that master geometry.

Read `docs/CODE_WALKTHROUGH_ELI5.md` for the detailed tour.

---

# 6. Why the effect stack order matters

If you do:

```text
Wave → Vortex
```

the vortex bends an already-waved shape.

If you do:

```text
Vortex → Wave
```

the wave acts on a shape whose points have already rotated.

Those are different designs.

This is intentional. Reordering fields is part of the design language, not housekeeping.

---

# 7. SVG export: an important detail

The tool exports **real SVG path geometry**, but the current engine flattens the font's original Bézier curves into many line segments before deformation.

That choice makes arbitrary deformation much easier and predictable, but it means the exported SVG can contain many points.

For actual trademark/master-logo finishing, the professional workflow is:

1. Discover the form in Field Lab.
2. Export SVG.
3. Open the winning version in Illustrator, Affinity Designer, Inkscape, Glyphs, RoboFont, etc.
4. Simplify/redraw the final curves deliberately.
5. Bring the cleaned master SVG back into a future Field Lab version for campaign treatments.

This is a design-lab tradeoff, not a hidden limitation.

---

# 8. Files worth reading

- `START_HERE.md` — shortest practical guide.
- `docs/CODE_WALKTHROUGH_ELI5.md` — detailed code explanation.
- `docs/ARCHITECTURE.md` — software structure and data flow.
- `docs/BUILD_AND_DESIGN_SHEET.md` — product/design decisions and planned evolution.
- `docs/OPEN_SOURCE_AND_COLLABS.md` — how to turn this into a public creative tool later.
- `docs/TROUBLESHOOTING.md` — first-run issues and fixes.

---

# 9. What this version intentionally does NOT pretend to be

This is a serious V1 lettermark laboratory, not a finished replacement for Illustrator, Glyphs, Photoshop, or TouchDesigner.

The biggest missing professional features are:

- Native cubic Bézier editing and handles.
- Automatic curve fitting after deformation.
- Arbitrary SVG import.
- Multiple independently named masks per field.
- True layer blending/compositing modes.
- A timeline/keyframe editor.
- GPU raster effects / GLSL effect graph.
- Persistent on-disk variant gallery with thumbnails.
- Plugin API.
- Collaboration/networking.

The architecture is designed so those can be added without rewriting the conceptual model.

---

# 10. Recommended development direction

For BRACT logo creation, prioritize in this order:

1. Better curve geometry and cubic Bézier reconstruction.
2. Native SVG import and re-export.
3. Region selection / contour segment locking.
4. Better sculpt tools: smooth, inflate, pinch, magnet, flatten.
5. Persistent branch/variant browser.
6. Constraint system for optical consistency.
7. GPU-based raster FIELD workspace.
8. Animation timeline.
9. Plugin/effect SDK.
10. Open-source packaging.

The important principle: **do not let “cool effects” outrun letterform quality.**
