# TROUBLESHOOTING

## Processing says the sketch folder name is wrong
The main file is `BLUME_Field_Lab.pde`, so the parent folder must be named `BLUME_Field_Lab`.

## Font fails to load
Try a normal desktop `.ttf` or `.otf`. Variable/color fonts and unusual wrappers may not behave uniformly through Java's `Font.createFont` path.

If a specific font fails:
1. Try another static cut of the family.
2. Confirm the file opens in your operating system font viewer.
3. Try a TTF version if both TTF and OTF are offered.

## Counters deform when Counter Lock is high
Counter detection uses contour winding orientation. Very unusual fonts can violate the assumption.

Use the per-field paint mask to protect those regions manually.

## The exported SVG has too many points
Increase `Outline Detail` before rebuilding the glyph, or simplify the exported winning mark in a vector editor.

For final production the planned solution is automatic cubic Bézier fitting.

## Raster Preview is slow
Atkinson dithering is CPU-based and touches many pixels. Disable Raster Preview while shaping geometry, then turn it on only for treatment evaluation.

## PNG export is slow at 3200+ px
Expected for CPU raster dither. SVG export is preferred for logo-master work.

## My manual sculpt disappeared after changing Outline Detail/font/glyph
Changing the source glyph rebuilds its sampled topology. Manual point offsets belong to that topology and therefore reset when the source is rebuilt.

Save a preset/variant first if you want to preserve the current branch.

## UI panels overlap at small window sizes
The first version assumes a desktop-sized window. Use approximately 1440×900 or larger for comfortable editing.

## Processing throws a Java2D/PGraphics error on render
Make sure you are using Processing 4 Java Mode. If the issue persists, copy the entire error text; it will identify the exact API mismatch and is usually straightforward to patch.
