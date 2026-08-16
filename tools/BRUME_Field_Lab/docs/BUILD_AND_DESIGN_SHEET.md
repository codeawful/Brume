# BUILD + DESIGN SHEET

## Product thesis

**Field Lab is a lettermark design environment that uses procedural physics as a sketching partner, then gives control back to the designer.**

The differentiator is not “more effects.” It is the loop:

```text
TYPE SOURCE → PROCEDURE → PROTECTION → HAND EDIT → COMPARE → VECTOR MASTER
```

---

# Primary user

A designer/art director creating a logo or lettermark who wants:

- More generative discovery than Illustrator alone.
- More structural control than an image filter.
- Reproducible states instead of destructive experiments.
- A bridge between type design, creative coding, and identity systems.

---

# BRUME-specific creative target

The canonical `B` should be able to exist in at least four states:

## 1. MASTER
Clean vector mark. No raster treatment required.

## 2. SIGNAL
Localized horizontal disturbance that is still unquestionably the same B.

## 3. LOW VISIBILITY
More degraded campaign treatment; counters/stem remain recognizable enough to preserve identity.

## 4. EVENT
Experimental extreme for motion, posters, collaborations, and one-off cultural work.

All four should derive from the same master geometry or saved recipe system.

---

# Interaction design principles

## Direct manipulation before inspector sliders
If a parameter has a spatial meaning, it should eventually have an on-canvas handle.

Examples:
- Field center → draggable crosshair.
- Radius → draggable ring.
- Wave direction → rotatable arrow.
- Focus band → visible horizontal region.

## Protect first-class brand anatomy
Recognition controls belong beside creative controls, not in an “advanced” drawer.

## State should always be branchable
A designer should never hesitate to experiment because they fear losing a good state.

## Effects should reveal their geometry
The tool should optionally visualize force vectors, masks, falloff, and contour movement. This makes the machine learnable rather than magical.

---

# V1 implementation choices

## Processing / Java
Chosen because:
- Fast creative-code feedback loop.
- Direct Java2D font outline access.
- Easy pixel manipulation.
- Cross-platform desktop behavior.
- Can later incorporate GLSL/OpenGL for heavy visual effects.

## No third-party UI library
Chosen to reduce installation friction for an eventual open-source release.

Tradeoff: the current custom UI is deliberately simpler than a mature desktop application's widget system.

## Flattened contour geometry
Chosen because arbitrary field deformation is straightforward and deterministic on point samples.

Tradeoff: SVG exports are point-dense and not final type-quality cubic curves.

---

# Professional V2 priorities

## A. Cubic Bézier reconstruction — highest priority
After deformation, fit smooth cubic curves to the point cloud.

Candidate approach:
- Segment contour by curvature changes.
- Ramer–Douglas–Peucker simplification as a first reduction.
- Schneider-style cubic curve fitting.
- Preserve corners intentionally.
- Error tolerance slider.

This transforms Field Lab from “excellent generative sketch exporter” into a much more credible master-mark constructor.

## B. Native SVG import
Not every collaborator will start from a font.

Load arbitrary paths, normalize them into the same geometry engine, then send them through Field Stack.

## C. Better manual form tools
- Push/Pull.
- Smooth.
- Pinch.
- Inflate.
- Flatten.
- Magnet.
- Knife/split contour.
- Select segment.
- Select contour.
- Lock segment.

## D. Constraint graph
Examples:
- Keep counter area above a minimum.
- Preserve stem angle.
- Keep two selected points horizontally aligned.
- Mirror one region.
- Limit local curvature.
- Preserve total width.

## E. Persistent variant browser
Every variant gets:
- Thumbnail.
- Name.
- Parent variant.
- Timestamp.
- Notes.
- Tags.
- Star/rating.

A branch graph would be more useful than a linear history for long creative sessions.

## F. GPU FIELD workspace
Processing P2D + GLSL shaders for:
- Refraction.
- Smear.
- Feedback.
- Threshold/noise.
- Directional blur.
- Live dither.
- Halftone.
- Scan displacement.

Keep it visually separate from FORM workspace so raster experimentation cannot obscure logo construction.

## G. Timeline
Animate any field/mask parameter with keyframes.

This is secondary for logo design but high-value for the later public/collab version.

---

# Open-source-ready API concept

Long-term, a field should be creatable in code without the UI:

```java
GlyphShape b = GlyphLoader.fromFont(font, "B");

b.manual()
 .protectCounters(0.9f)
 .protectLeftStem(0.8f, 0.18f);

b.fields()
 .add(new WaveField().amplitude(.07f).frequency(9).focusY(.51f))
 .add(new SliceField().amplitude(.04f).bands(70));

SVG.write(b, "brume-b.svg");
```

The UI then becomes one client of the engine rather than the engine itself.

---

# Definition of “ready to open source”

Do not publish only because the code runs.

Recommended gate:

- Stable preset format with migration/versioning.
- Automated tests for field determinism and SVG validity.
- No brand-owned font files bundled.
- No hard dependency on BRUME artwork.
- Example public-domain/open fonts only, or none bundled.
- CONTRIBUTING guide.
- Code of Conduct if community contribution is desired.
- Chosen software license.
- Screenshots/GIFs.
- 3–5 example workflows.
- Clear separation between engine and branded demo UI.
- Security review of file parsing before broad SVG import.
