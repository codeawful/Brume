# CODE WALKTHROUGH — ELI5, THEN DEEPER

This document explains the program as if we were building a physical machine together.

---

# 1. The six big pieces

Think of Field Lab as six boxes connected by arrows:

```text
FONT
  ↓
GLYPH DOCUMENT
  ↓
MANUAL FORM EDITS
  ↓
FIELD STACK + MASKS + PROTECTION
  ↓
VECTOR MASTER
  ↓
RASTER PREVIEW / EXPORT
```

The code mirrors those boxes.

---

# 2. `BRACT_Field_Lab.pde` — the front door

Processing looks for the `.pde` file that has the same name as the sketch folder.

This file does four boring-but-important jobs:

1. Creates the window.
2. Creates the application's main objects.
3. Calls update/draw every frame.
4. Receives mouse/keyboard/file-picker events and hands them to the UI/model.

ELI5 analogy: this is the building lobby. It does not manufacture the logo. It tells you which room to go to.

Important line conceptually:

```java
appModel.updateIfNeeded();
```

The tool only rebuilds the expensive image when something changes. That keeps interaction faster.

---

# 3. `GlyphDocument.pde` — where a font stops being “text”

## What Java gives us

A font is not fundamentally a bitmap. It contains mathematical outlines.

Java's font system gives us a `GlyphVector`, and a `GlyphVector` can give us a `Shape`.

Very simplified:

```java
GlyphVector gv = awtFont.createGlyphVector(frc, glyphText);
Shape shape = gv.getOutline();
```

ELI5:

```text
"B" typed in a font
      ↓
ask Java for its edge
      ↓
actual shape of the B
```

## Why `PathIterator` exists

A font outline normally contains straight lines and Bézier curves.

Arbitrary deformation of Bézier control handles is possible, but substantially harder to make predictable.

So V1 asks Java to **flatten** the curves into many small line segments:

```java
PathIterator it = shape.getPathIterator(null, flattening);
```

Think of a perfect circle being approximated with lots of tiny straight edges. At enough resolution, it still looks round.

The `Outline Detail` slider controls this tradeoff.

### Lower flatness value
More points, more detail, heavier computation.

### Higher flatness value
Fewer points, faster and more graphic/polygonal.

---

# 4. Every point has three lives

`GlyphPoint` contains:

```java
PVector base;
PVector manual;
PVector pos;
```

### `base`
The untouched font.

### `manual`
Your sculpt/node correction stored as an offset from the font.

### `pos`
The final result after procedural fields.

Conceptually:

```text
base + manual = designer's source shape
source shape + fields = displayed/exported shape
```

That separation is one of the most important architectural decisions in the project.

If procedural effects overwrote `base`, you could never safely return to the font or branch experiments.

---

# 5. `Fields.pde` — invisible forces

Every field follows the same promise:

```java
PVector apply(PVector current, PVector base, float time)
```

It receives a point and returns where that point should go next.

That means the app does not care whether the field is a wave, vortex, lens, noise system, or something you invent later.

This is polymorphism, but the ELI5 meaning is simply:

> Every effect plugs into the machine using the same shaped plug.

## Example: Wave Field

The important idea is:

```java
sin(...)
```

A sine wave repeatedly moves smoothly from `-1` to `+1`.

We multiply that by `amplitude`:

```text
small amplitude = tiny movement
large amplitude = large movement
```

Then we multiply it by an envelope centered around Focus Y:

```java
float d = (base.y - centerY) / spread;
float envelope = exp(-d * d);
```

ELI5: imagine a flashlight shining across the B. The center of the beam is strong; the edges fade away. Only the points in the bright part receive the full wave.

That is why BRACT can disturb the waist without making the entire B wobbly.

---

# 6. Why fields run in a stack

The deformation loop essentially says:

```java
current = source;
current = field1.apply(current);
current = field2.apply(current);
current = field3.apply(current);
```

The output of one field is the input of the next.

So effect order creates new forms.

This is the same reason “blur then sharpen” differs from “sharpen then blur.”

---

# 7. Masks — permission maps

Every field owns a tiny grayscale `PaintMask` grid.

A value of:

```text
1.0 = yes, effect can happen here
0.0 = no, protect this area
0.5 = half strength
```

When painting, the app modifies nearby cells with a soft falloff.

When deforming a vector point, it samples the mask at that point's original normalized X/Y position.

Then:

```java
mixAmount = mask × protection × globalEffectMix
```

This is not simply “painting pixels.” The mask is controlling how much *vector displacement* a point receives.

---

# 8. Protection — brand recognition seat belts

For a B, two areas are unusually important:

- The left stem.
- The counters/holes.

So the tool can automatically reduce deformation there.

## Counter detection

Font outlines are made of multiple contours. The outer silhouette usually winds in one direction, while holes wind in the opposite direction.

Field Lab finds the largest contour and treats its direction as “outside.” Contours winding the opposite way are marked `hole = true`.

Then Counter Lock reduces field influence on those contours.

This is a practical heuristic. Some unusual fonts may need manual masks instead.

## Stem protection

The normalized glyph lives in roughly a 0–1 square.

If a point is near the left side, Stem Lock increasingly protects it.

This is deliberately B-friendly but still useful for many Latin letterforms.

---

# 9. Sculpt mode — the difference between a generator and a design tool

Procedural fields are great at surprise but terrible at taste.

Sculpt mode lets your hand override the machine.

When you drag, the program calculates:

1. How far each contour point is from the brush center.
2. A soft influence weight.
3. How far your mouse moved.
4. Adds some fraction of that mouse movement to `gp.manual`.

So nearby contour points follow your gesture.

Alt/right-drag does the opposite: it multiplies manual offsets toward zero, relaxing the letter toward its original font source.

That gives you a reversible design workflow rather than destructive mesh pushing.

---

# 10. Node mode — surgery

Node mode shows the sampled outline points and lets you move one point directly.

This is not yet Illustrator-style Bézier editing because the points are flattened samples rather than curve anchors/handles.

Its role is surgical cleanup after broader Sculpt/Field moves.

---

# 11. Max Travel — preventing mathematical explosions

Strong fields can push a point very far.

For logo exploration, it is useful to have a hard safety rail.

The program measures the procedural displacement from the manually edited source:

```java
PVector delta = current - manualSource;
```

If its length exceeds `maxDisplacement`, it gets shortened.

Your hand edits are not capped by Max Travel. The machine is.

That distinction is intentional.

---

# 12. `RasterFX.pde` — costume, not skeleton

Raster Preview takes a rendered image of the final vector shape and optionally applies:

- Bayer dither.
- Atkinson dither.
- Scan cuts.
- Grain.

It does **not** feed those pixels back into the vector geometry.

This is deliberate.

A logo should not accidentally depend on a 900-pixel preview effect to exist.

Use raster effects to discover campaign language or evaluate treatment. Use geometry fields + manual sculpting to design the canonical mark.

---

# 13. Atkinson dithering in plain English

For every pixel:

1. Decide whether it becomes ON or OFF.
2. Calculate how wrong that decision was compared with the original gray value.
3. Give small pieces of that error to nearby future pixels.

The eye averages the resulting pattern and perceives intermediate tone.

This is why error-diffusion dithering feels less like a regular grid than ordered Bayer dithering.

---

# 14. Presets are recipes

A preset JSON stores:

- Glyph.
- Font path/name.
- Outline detail.
- Your manual geometry offsets.
- Protection settings.
- Every field and parameter.
- Every field mask.
- Raster preview settings.

That means a BRACT visual state can be represented as data rather than a mystery PSD file.

This is the foundation for future collaboration and open source.

---

# 15. Variants are branches

Shift-clicking a variant button stores the entire current JSON state in memory.

Clicking it later restores that branch.

The next professional evolution is an on-disk graph of named branches with thumbnails and parent/child relationships — essentially lightweight Git thinking for visual forms.

---

# 16. SVG export

The export loops through every deformed contour point and writes:

```text
M x y
L x y
L x y
...
Z
```

Because the path uses `fill-rule="evenodd"`, counter contours become holes.

The output is real vector geometry, but many line segments.

A future curve-fitting pass should convert the winning polygonal contour back to high-quality cubic Bézier curves.

---

# 17. Where to modify code when you get curious

## Want a new procedural deformation?
Edit `Fields.pde`.

1. Create a class extending `GeometryField`.
2. Register parameters with `param(...)`.
3. Write `apply(...)`.
4. Add the type to `createFieldByType(...)`.
5. Add a button in the UI's field add list.

## Want a new raster treatment?
Edit `RasterFX.pde`.

## Want a new UI control?
Edit `EditorUI.pde`.

## Want better contour/curve handling?
Edit `GlyphDocument.pde`.

That file is the heart of the future “professional logo tool” evolution.
