class GlyphPoint {
  PVector base;
  PVector pos;
  PVector manual; // permanent designer edit applied BEFORE procedural fields
  boolean hole;

  GlyphPoint(float x, float y, boolean isHole) {
    base = new PVector(x, y);
    manual = new PVector(0, 0);
    pos = base.copy();
    hole = isHole;
  }
}

class GlyphContour {
  ArrayList<GlyphPoint> points = new ArrayList<GlyphPoint>();
  boolean hole = false;
  float signedArea = 0;
}

class GlyphDocument {
  PApplet p;
  Font awtFont;
  String fontName = "Serif";
  String glyphText = "B";
  float flattening = 0.85f; // font-space flatness for converting Beziers to many line points

  ArrayList<GlyphContour> contours = new ArrayList<GlyphContour>();
  PImage previewImage;

  GlyphDocument(PApplet parent) {
    p = parent;
  }

  void setSystemFont(String name) {
    fontName = (name == null || name.length() == 0) ? "Serif" : name;
    awtFont = new Font(fontName, Font.PLAIN, 1000);
    rebuild();
  }

  void loadFontFile(File f) throws Exception {
    Font loaded = Font.createFont(Font.TRUETYPE_FONT, f);
    awtFont = loaded.deriveFont(1000.0f);
    fontName = loaded.getFamily();
    rebuild();
  }

  void setGlyph(String s) {
    if (s == null || s.length() == 0) s = "B";
    glyphText = s;
    rebuild();
  }

  void rebuild() {
    if (awtFont == null) return;

    contours.clear();
    FontRenderContext frc = new FontRenderContext(new AffineTransform(), true, true);
    // TextLayout gives short wordmarks proper shaping/positioning while still yielding a vector outline.
    TextLayout layout = new TextLayout(glyphText, awtFont, frc);
    Shape shape = layout.getOutline(null);
    Rectangle2D bounds = shape.getBounds2D();
    if (bounds.getWidth() <= 0 || bounds.getHeight() <= 0) return;

    // Keep the original aspect ratio by normalizing against ONE scale, not X/Y separately.
    double maxDim = Math.max(bounds.getWidth(), bounds.getHeight());
    double padX = (1.0 - bounds.getWidth() / maxDim) * 0.5;
    double padY = (1.0 - bounds.getHeight() / maxDim) * 0.5;

    PathIterator it = shape.getPathIterator(null, flattening);
    double[] c = new double[6];
    GlyphContour current = null;

    while (!it.isDone()) {
      int type = it.currentSegment(c);
      if (type == PathIterator.SEG_MOVETO) {
        current = new GlyphContour();
        contours.add(current);
        addNormalizedPoint(current, c[0], c[1], bounds, maxDim, padX, padY);
      } else if (type == PathIterator.SEG_LINETO) {
        if (current != null) addNormalizedPoint(current, c[0], c[1], bounds, maxDim, padX, padY);
      } else if (type == PathIterator.SEG_CLOSE) {
        current = null;
      }
      it.next();
    }

    // Determine orientation. The largest contour tells us the outer contour winding sign.
    float largestAbs = -1;
    float outerSign = 1;
    for (GlyphContour gc : contours) {
      gc.signedArea = polygonArea(gc);
      if (abs(gc.signedArea) > largestAbs) {
        largestAbs = abs(gc.signedArea);
        outerSign = gc.signedArea >= 0 ? 1 : -1;
      }
    }
    for (GlyphContour gc : contours) {
      gc.hole = (gc.signedArea >= 0 ? 1 : -1) != outerSign;
      for (GlyphPoint gp : gc.points) gp.hole = gc.hole;
    }
  }

  void addNormalizedPoint(GlyphContour contour, double x, double y, Rectangle2D b, double maxDim, double padX, double padY) {
    float nx = (float)(padX + (x - b.getX()) / maxDim);
    float ny = (float)(padY + (y - b.getY()) / maxDim);
    contour.points.add(new GlyphPoint(nx, ny, false));
  }

  float polygonArea(GlyphContour c) {
    if (c.points.size() < 3) return 0;
    double a = 0;
    for (int i = 0; i < c.points.size(); i++) {
      PVector p0 = c.points.get(i).base;
      PVector p1 = c.points.get((i + 1) % c.points.size()).base;
      a += p0.x * p1.y - p1.x * p0.y;
    }
    return (float)(a * 0.5);
  }

  void deform(ArrayList<GeometryField> fields, AppModel app, float time) {
    if (contours.size() == 0) return;

    for (GlyphContour c : contours) {
      for (GlyphPoint gp : c.points) {
        // Start from the designer-edited master geometry, then let procedural fields act on it.
        PVector current = PVector.add(gp.base, gp.manual);

        // ELI5: these are the "seat belts" that stop the B becoming random soup.
        float protectionMix = 1.0f;

        if (gp.hole) protectionMix *= (1.0f - app.counterProtect);

        if (!gp.hole && gp.base.x < app.stemWidth) {
          float acrossStem = smooth01(gp.base.x / max(0.0001f, app.stemWidth));
          float protectHere = app.stemProtect * (1.0f - acrossStem);
          protectionMix *= (1.0f - protectHere);
        }

        if (!app.previewBypass) for (GeometryField f : fields) {
          if (!f.enabled) continue;
          PVector before = current.copy();
          PVector after = f.apply(current, gp.base, time);
          float maskAmount = f.mask.sample(gp.base.x, gp.base.y);
          float mixAmount = constrain(maskAmount * protectionMix * app.globalEffectMix * f.mix, 0, 1);
          current = PVector.lerp(before, after, mixAmount);
        }

        // Final safety clamp: no point can teleport farther than maxDisplacement from its source.
        // maxDisplacement applies to the PROCEDURAL travel from the manually edited source.
        PVector manualSource = PVector.add(gp.base, gp.manual);
        PVector delta = PVector.sub(current, manualSource);
        if (delta.mag() > app.maxDisplacement) {
          delta.normalize().mult(app.maxDisplacement);
          current = PVector.add(manualSource, delta);
        }
        gp.pos.set(current);
      }
    }
  }

  float smooth01(float x) {
    x = constrain(x, 0, 1);
    return x * x * (3 - 2 * x);
  }

  void ensureDeformed(ArrayList<GeometryField> fields, AppModel app, float time) {
    deform(fields, app, time);
  }

  Path2D.Float buildPath(float size, float margin) {
    Path2D.Float path = new Path2D.Float(Path2D.WIND_EVEN_ODD);
    float draw = size - margin * 2;
    for (GlyphContour c : contours) {
      if (c.points.size() < 2) continue;
      GlyphPoint first = c.points.get(0);
      path.moveTo(margin + first.pos.x * draw, margin + first.pos.y * draw);
      for (int i = 1; i < c.points.size(); i++) {
        GlyphPoint gp = c.points.get(i);
        path.lineTo(margin + gp.pos.x * draw, margin + gp.pos.y * draw);
      }
      path.closePath();
    }
    return path;
  }

  PImage renderVectorToImage(int sizePx, int fgColor, boolean transparent, int bgColor) {
    // Use Java2D directly here instead of reaching into Processing's renderer internals.
    // This keeps the glyph engine portable and makes transparent export predictable.
    BufferedImage bi = new BufferedImage(sizePx, sizePx, BufferedImage.TYPE_INT_ARGB);
    Graphics2D g = bi.createGraphics();
    g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
    g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);

    if (!transparent) {
      g.setColor(new Color(redInt(bgColor), greenInt(bgColor), blueInt(bgColor), 255));
      g.fillRect(0, 0, sizePx, sizePx);
    }

    g.setColor(new Color(redInt(fgColor), greenInt(fgColor), blueInt(fgColor), 255));
    g.fill(buildPath(sizePx, sizePx * 0.08f));
    g.dispose();

    int[] rgb = bi.getRGB(0, 0, sizePx, sizePx, null, 0, sizePx);
    PImage out = new PImage(sizePx, sizePx, ARGB);
    out.loadPixels();
    arrayCopy(rgb, out.pixels);
    out.updatePixels();
    return out;
  }

  int redInt(int c) { return (c >> 16) & 255; }
  int greenInt(int c) { return (c >> 8) & 255; }
  int blueInt(int c) { return c & 255; }

  void renderPreview(int sizePx, RasterFX fx) {
    PImage base = renderVectorToImage(sizePx, color(232, 230, 225), true, color(0));
    previewImage = fx.enabled ? fx.apply(base) : base;
  }

  JSONObject manualToJSON() {
    JSONObject root = new JSONObject();
    JSONArray cs = new JSONArray();
    for (int ci = 0; ci < contours.size(); ci++) {
      GlyphContour c = contours.get(ci);
      JSONArray pts = new JSONArray();
      for (int pi = 0; pi < c.points.size(); pi++) {
        GlyphPoint gp = c.points.get(pi);
        JSONObject pj = new JSONObject();
        pj.setFloat("x", gp.manual.x);
        pj.setFloat("y", gp.manual.y);
        pts.setJSONObject(pi, pj);
      }
      JSONObject cj = new JSONObject();
      cj.setJSONArray("points", pts);
      cs.setJSONObject(ci, cj);
    }
    root.setJSONArray("contours", cs);
    return root;
  }

  void manualFromJSON(JSONObject root) {
    if (root == null) return;
    JSONArray cs = root.getJSONArray("contours");
    if (cs == null) return;
    int cCount = min(cs.size(), contours.size());
    for (int ci = 0; ci < cCount; ci++) {
      JSONArray pts = cs.getJSONObject(ci).getJSONArray("points");
      if (pts == null) continue;
      GlyphContour c = contours.get(ci);
      int pCount = min(pts.size(), c.points.size());
      for (int pi = 0; pi < pCount; pi++) {
        JSONObject pj = pts.getJSONObject(pi);
        c.points.get(pi).manual.set(pj.getFloat("x", 0), pj.getFloat("y", 0));
      }
    }
  }

  void clearManualEdits() {
    for (GlyphContour c : contours) for (GlyphPoint gp : c.points) gp.manual.set(0, 0);
  }

  PVector manualSource(GlyphPoint gp) {
    return PVector.add(gp.base, gp.manual);
  }

  void writePNG(File f, int sizePx, RasterFX fx, boolean transparent, int bgColor, int fgColor) {
    PImage img = renderVectorToImage(sizePx, fgColor, transparent, bgColor);
    if (fx.enabled) img = fx.apply(img);
    img.save(f.getAbsolutePath());
  }

  void writeSVG(File f, int canvasSize, String fillHex) {
    PrintWriter out = createWriter(f.getAbsolutePath());
    float margin = canvasSize * 0.08f;
    float draw = canvasSize - margin * 2;

    out.println("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
    out.println("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"" + canvasSize + "\" height=\"" + canvasSize + "\" viewBox=\"0 0 " + canvasSize + " " + canvasSize + "\">");
    out.println("  <path fill=\"" + fillHex + "\" fill-rule=\"evenodd\" d=\"");

    for (GlyphContour c : contours) {
      if (c.points.size() < 2) continue;
      GlyphPoint first = c.points.get(0);
      out.print("M " + nf(margin + first.pos.x * draw, 0, 3) + " " + nf(margin + first.pos.y * draw, 0, 3) + " ");
      for (int i = 1; i < c.points.size(); i++) {
        GlyphPoint gp = c.points.get(i);
        out.print("L " + nf(margin + gp.pos.x * draw, 0, 3) + " " + nf(margin + gp.pos.y * draw, 0, 3) + " ");
      }
      out.print("Z ");
    }
    out.println("\"/>");
    out.println("</svg>");
    out.flush();
    out.close();
  }
}
