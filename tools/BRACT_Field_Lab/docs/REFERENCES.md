# PRIMARY TECHNICAL REFERENCES

These are the upstream APIs the current architecture is based on.

## Processing

- Download / current release: https://processing.org/download/
- Processing reference: https://processing.org/reference/
- `createGraphics()`: https://processing.org/reference/createGraphics_
- `PGraphics`: https://processing.org/reference/PGraphics
- `PFont`: https://processing.org/reference/PFont
- Processing 4 source: https://github.com/processing/processing4

At the time this build was prepared (August 2026), the official download page lists **Processing 4.5.6**.

## Java font geometry

- `java.awt.Font`: https://docs.oracle.com/en/java/javase/21/docs/api/java.desktop/java/awt/Font.html
- `java.awt.font.GlyphVector`: https://docs.oracle.com/en/java/javase/21/docs/api/java.desktop/java/awt/font/GlyphVector.html
- `java.awt.font.TextLayout`: https://docs.oracle.com/en/java/javase/21/docs/api/java.desktop/java/awt/font/TextLayout.html
- `java.awt.geom.PathIterator`: https://docs.oracle.com/en/java/javase/21/docs/api/java.desktop/java/awt/geom/PathIterator.html

The central design choice is to obtain an actual font outline as a Java `Shape`, flatten it into controllable contour samples for deformation, and export the resulting geometry rather than treating the source letter as a screenshot.
