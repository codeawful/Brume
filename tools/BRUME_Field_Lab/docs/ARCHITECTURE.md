# ARCHITECTURE

## Design goal

Keep the **letterform engine independent from BRUME-specific aesthetics** so the project can later become a collaboration/open-source instrument.

## Runtime data flow

```text
Local Font (.ttf/.otf) or System Font
             │
             ▼
      java.awt.Font
             │
             ▼
         GlyphVector
             │
             ▼
       Java2D Shape
             │
             ▼
 PathIterator(flattening)
             │
             ▼
  normalized GlyphContours
             │
             ├───────────────┐
             ▼               │
      manual offsets         │
  (Sculpt / Node edits)      │
             │               │
             ▼               │
       designer source       │
             │               │
             ▼               │
     ordered field stack     │
             │               │
      per-field masks        │
             │               │
   structural protection     │
             │               │
             ▼               │
       deformed vector       │
        │            │       │
        │            └───────┘ serialized into JSON preset
        │
        ├────► SVG path export
        │
        └────► Java2D render ─► RasterFX ─► PNG / preview
```

---

# File responsibilities

## `BRUME_Field_Lab.pde`
Composition root and event forwarding.

## `AppModel.pde`
Owns application state, active fields, global protection, serialization, and export orchestration.

## `GlyphDocument.pde`
Font loading, glyph extraction, contour normalization, manual geometry, hole detection, deformation loop, vector/raster rendering, SVG export.

This is the most important engine module.

## `Fields.pde`
Field interface and effect implementations. New deformation ideas should be modular classes here rather than conditionals inside the renderer.

## `PaintMask.pde`
Small normalized grayscale masks. Independent of screen resolution.

## `RasterFX.pde`
Non-destructive image-level effects.

## `HistoryVariants.pde`
State snapshots. Uses serialized JSON as the source of truth so undo and variants exercise the same persistence system as disk presets.

## `EditorUI.pde`
Immediate-style custom UI, direct manipulation, Sculpt, Nodes, mask painting, variant interaction.

---

# Architectural rules for future development

1. **Base geometry must remain immutable.**
   - The font-derived `base` is provenance.
   - Hand edits live in `manual`.
   - Procedural results live in `pos`.

2. **Raster effects never silently mutate vector geometry.**

3. **Fields must be deterministic when animation is off.**
   - Seeds are explicit.
   - This makes presets reproducible.

4. **Everything important should serialize.**
   - If a design cannot be recreated from its saved state, it is not a proper generative identity asset.

5. **Open-source core should not know the brand name.**
   - The current UI can say BRUME.
   - Engine classes should stay generic.

6. **Field order is semantic.**
   - Do not auto-sort effects.

7. **Protection is separate from effect math.**
   - This allows the same effect to be used aggressively or conservatively depending on the identity.

---

# Recommended V2 module split

As the code grows, migrate from PDE tabs into a proper Java/Gradle project:

```text
src/
  engine/
    GlyphSource.java
    GlyphGeometry.java
    Contour.java
    CurveFitter.java
    GeometryField.java
    FieldStack.java
    Mask.java
    Constraint.java
  effects/
    WaveField.java
    SliceField.java
    VortexField.java
    ...
  raster/
    Dither.java
    ShaderGraph.java
  io/
    PresetCodec.java
    SVGReader.java
    SVGWriter.java
  ui/
    EditorApp.java
    CanvasView.java
    Inspector.java
    VariantBrowser.java
```

Processing can remain the rendering/application shell while the engine becomes ordinary Java classes that are easier to unit test and publish as a library.
