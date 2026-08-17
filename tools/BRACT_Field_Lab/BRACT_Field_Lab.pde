/*
  BRACT FIELD LAB
  ----------------
  A geometry-first lettermark design instrument built in Processing 4.

  ELI5:
  - A font gives us the outline of a letter.
  - We turn that outline into lots of points.
  - "Fields" push those points around using math.
  - Masks say where each field is allowed to act.
  - Protection controls keep important anatomy readable.
  - Raster Preview lets you audition dither / scan / grain without damaging the vector master.

  This sketch intentionally uses no third-party Processing libraries.
*/

import java.awt.Font;
import java.awt.Shape;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.awt.font.FontRenderContext;
import java.awt.font.GlyphVector;
import java.awt.font.TextLayout;
import java.awt.geom.AffineTransform;
import java.awt.geom.PathIterator;
import java.awt.geom.Path2D;
import java.awt.geom.Rectangle2D;
import java.io.File;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;

AppModel appModel;
EditorUI ui;
HistoryManager history;
VariantManager variants;

void settings() {
  size(1600, 1000, P2D);
  smooth(8);
}

void setup() {
  surface.setResizable(true);
  surface.setTitle("BRACT FIELD LAB — Lettermark Geometry Instrument");

  appModel = new AppModel(this);
  history = new HistoryManager(appModel, 80);
  variants = new VariantManager(appModel, 6);
  ui = new EditorUI(this, appModel, history, variants);

  // Start with a system serif so the app works before you load any font file.
  appModel.document.setSystemFont("Serif");
  appModel.document.setGlyph("B");
  appModel.addField(new WaveField());
  appModel.addField(new SliceField());
  appModel.activeFieldIndex = 0;
  appModel.loadBractStarterState();
  history.reset();
}

void draw() {
  background(appModel.themeBg);
  ui.layout(width, height);

  // Update the geometry only when something changed, unless animation is enabled.
  if (appModel.animate) {
    appModel.animationTime = millis() / 1000.0f;
    appModel.markDirty();
  }
  appModel.updateIfNeeded();

  ui.draw();
}

void mousePressed() {
  ui.mousePressed(mouseX, mouseY, mouseButton);
}

void mouseDragged() {
  ui.mouseDragged(mouseX, mouseY, mouseButton);
}

void mouseReleased() {
  ui.mouseReleased(mouseX, mouseY, mouseButton);
}

void mouseWheel(processing.event.MouseEvent event) {
  ui.mouseWheel(event.getCount(), mouseX, mouseY);
}

void keyPressed() {
  ui.keyPressed(key, keyCode);
}

void keyTyped() {
  ui.keyTyped(key);
}

void keyReleased() {
  ui.keyReleased(key, keyCode);
}

// Processing file-picker callbacks ------------------------------------------------

void fontFileSelected(File selection) {
  if (selection == null) return;
  try {
    appModel.document.loadFontFile(selection);
    appModel.fontPath = selection.getAbsolutePath();
    appModel.status("Loaded font: " + selection.getName());
    appModel.markDirty();
    history.commit("Load font");
  }
  catch (Exception ex) {
    appModel.status("Font load failed: " + ex.getMessage());
    ex.printStackTrace();
  }
}

void presetFileSelected(File selection) {
  if (selection == null) return;
  try {
    appModel.loadPreset(selection);
    appModel.status("Loaded preset: " + selection.getName());
    history.reset();
  }
  catch (Exception ex) {
    appModel.status("Preset load failed: " + ex.getMessage());
    ex.printStackTrace();
  }
}

void presetOutputSelected(File selection) {
  if (selection == null) return;
  try {
    File target = ensureExtension(selection, ".json");
    appModel.savePreset(target);
    appModel.status("Saved preset: " + target.getName());
  }
  catch (Exception ex) {
    appModel.status("Preset save failed: " + ex.getMessage());
    ex.printStackTrace();
  }
}

void svgOutputSelected(File selection) {
  if (selection == null) return;
  try {
    File target = ensureExtension(selection, ".svg");
    appModel.exportSVG(target, 1600);
    appModel.status("Exported SVG: " + target.getName());
  }
  catch (Exception ex) {
    appModel.status("SVG export failed: " + ex.getMessage());
    ex.printStackTrace();
  }
}

void pngOutputSelected(File selection) {
  if (selection == null) return;
  try {
    File target = ensureExtension(selection, ".png");
    appModel.exportPNG(target, appModel.exportSize);
    appModel.status("Exported PNG: " + target.getName());
  }
  catch (Exception ex) {
    appModel.status("PNG export failed: " + ex.getMessage());
    ex.printStackTrace();
  }
}

File ensureExtension(File f, String ext) {
  String p = f.getAbsolutePath();
  if (!p.toLowerCase().endsWith(ext)) p += ext;
  return new File(p);
}
