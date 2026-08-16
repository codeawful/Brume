class AppModel {
  PApplet p;
  GlyphDocument document;
  ArrayList<GeometryField> fields = new ArrayList<GeometryField>();
  RasterFX raster = new RasterFX();

  int activeFieldIndex = -1;
  String fontPath = "";
  boolean dirty = true;
  boolean animate = false;
  boolean previewBypass = false; // temporary "show me the clean/manual master" mode
  float animationTime = 0;

  // Global geometry protection. These are deliberately separate from field settings.
  float stemProtect = 0.72f;      // 0 = deform stem freely, 1 = nearly lock it
  float stemWidth = 0.20f;        // left-most normalized area treated as "stem"
  float counterProtect = 0.88f;   // protects hole contours (the B counters)
  float maxDisplacement = 0.20f;  // safety rail in normalized glyph space
  float globalEffectMix = 1.0f;

  // Display + export
  int themeBg = color(11, 12, 14);
  int themePanel = color(17, 18, 21);
  int themeLine = color(45, 48, 54);
  int themeText = color(232, 230, 225);
  int themeMuted = color(135, 140, 149);
  int themeAccent = color(198, 207, 218);
  int exportSize = 3200;
  boolean transparentExport = true;

  String statusMessage = "Ready.";
  long statusAt = 0;

  AppModel(PApplet parent) {
    p = parent;
    document = new GlyphDocument(parent);
  }

  void status(String s) {
    statusMessage = s;
    statusAt = millis();
  }

  void markDirty() {
    dirty = true;
  }

  void updateIfNeeded() {
    if (!dirty) return;
    document.deform(fields, this, animationTime);
    document.renderPreview(900, raster);
    dirty = false;
  }

  GeometryField activeField() {
    if (activeFieldIndex < 0 || activeFieldIndex >= fields.size()) return null;
    return fields.get(activeFieldIndex);
  }

  void addField(GeometryField f) {
    fields.add(f);
    activeFieldIndex = fields.size() - 1;
    markDirty();
  }

  void removeField(int idx) {
    if (idx < 0 || idx >= fields.size()) return;
    fields.remove(idx);
    activeFieldIndex = min(activeFieldIndex, fields.size() - 1);
    markDirty();
  }


  void duplicateActiveField() {
    GeometryField f = activeField();
    if (f == null) return;
    GeometryField copy = fieldFromJSON(parseJSONObject(f.toJSON().toString()));
    if (copy == null) return;
    int insertAt = constrain(activeFieldIndex + 1, 0, fields.size());
    fields.add(insertAt, copy);
    activeFieldIndex = insertAt;
    markDirty();
  }

  void moveField(int idx, int dir) {
    int ni = idx + dir;
    if (idx < 0 || idx >= fields.size() || ni < 0 || ni >= fields.size()) return;
    GeometryField a = fields.get(idx);
    fields.set(idx, fields.get(ni));
    fields.set(ni, a);
    activeFieldIndex = ni;
    markDirty();
  }

  void loadBrumeStarterState() {
    fields.clear();
    WaveField wave = new WaveField();
    wave.set("amplitude", 0.075f);
    wave.set("frequency", 8.5f);
    wave.set("phase", 0.15f);
    wave.set("centerY", 0.50f);
    wave.set("spread", 0.18f);
    wave.set("angle", 0.0f);
    fields.add(wave);

    SliceField slice = new SliceField();
    slice.set("amplitude", 0.045f);
    slice.set("bands", 58.0f);
    slice.set("jitter", 0.26f);
    slice.set("centerY", 0.52f);
    slice.set("spread", 0.22f);
    slice.set("seed", 23.0f);
    fields.add(slice);

    activeFieldIndex = 0;
    stemProtect = 0.78f;
    stemWidth = 0.18f;
    counterProtect = 0.90f;
    maxDisplacement = 0.18f;
    raster.enabled = false;
    markDirty();
  }

  // ----- SERIALIZATION ----------------------------------------------------------

  JSONObject toJSON() {
    JSONObject root = new JSONObject();
    root.setInt("formatVersion", 1);
    root.setString("glyph", document.glyphText);
    root.setString("fontPath", fontPath == null ? "" : fontPath);
    root.setString("fontName", document.fontName);
    root.setFloat("flattening", document.flattening);
    root.setJSONObject("manualGeometry", document.manualToJSON());

    JSONObject protection = new JSONObject();
    protection.setFloat("stemProtect", stemProtect);
    protection.setFloat("stemWidth", stemWidth);
    protection.setFloat("counterProtect", counterProtect);
    protection.setFloat("maxDisplacement", maxDisplacement);
    protection.setFloat("globalEffectMix", globalEffectMix);
    root.setJSONObject("protection", protection);

    root.setJSONObject("raster", raster.toJSON());

    JSONArray arr = new JSONArray();
    for (int i = 0; i < fields.size(); i++) arr.setJSONObject(i, fields.get(i).toJSON());
    root.setJSONArray("fields", arr);
    root.setInt("activeFieldIndex", activeFieldIndex);
    root.setInt("exportSize", exportSize);
    root.setBoolean("transparentExport", transparentExport);
    return root;
  }

  void fromJSON(JSONObject root) {
    if (root == null) return;

    String g = root.getString("glyph", "B");
    String fp = root.getString("fontPath", "");
    String fn = root.getString("fontName", "Serif");
    float flat = root.getFloat("flattening", 0.85f);

    document.flattening = flat;
    boolean fontLoaded = false;
    if (fp != null && fp.length() > 0) {
      File ff = new File(fp);
      if (ff.exists()) {
        try {
          document.loadFontFile(ff);
          fontPath = fp;
          fontLoaded = true;
        }
        catch (Exception ignored) {}
      }
    }
    if (!fontLoaded) {
      document.setSystemFont(fn);
      fontPath = "";
    }
    document.setGlyph(g);
    JSONObject manualGeometry = root.getJSONObject("manualGeometry");
    if (manualGeometry != null) document.manualFromJSON(manualGeometry);

    JSONObject protection = root.getJSONObject("protection");
    if (protection != null) {
      stemProtect = protection.getFloat("stemProtect", stemProtect);
      stemWidth = protection.getFloat("stemWidth", stemWidth);
      counterProtect = protection.getFloat("counterProtect", counterProtect);
      maxDisplacement = protection.getFloat("maxDisplacement", maxDisplacement);
      globalEffectMix = protection.getFloat("globalEffectMix", globalEffectMix);
    }

    JSONObject rj = root.getJSONObject("raster");
    if (rj != null) raster.fromJSON(rj);

    fields.clear();
    JSONArray arr = root.getJSONArray("fields");
    if (arr != null) {
      for (int i = 0; i < arr.size(); i++) {
        JSONObject fj = arr.getJSONObject(i);
        GeometryField f = fieldFromJSON(fj);
        if (f != null) fields.add(f);
      }
    }
    activeFieldIndex = constrain(root.getInt("activeFieldIndex", 0), -1, fields.size() - 1);
    exportSize = root.getInt("exportSize", exportSize);
    transparentExport = root.getBoolean("transparentExport", transparentExport);
    markDirty();
  }

  void savePreset(File f) {
    saveJSONObject(toJSON(), f.getAbsolutePath());
  }

  void loadPreset(File f) {
    JSONObject obj = loadJSONObject(f.getAbsolutePath());
    fromJSON(obj);
  }

  // ----- EXPORT -----------------------------------------------------------------

  void exportSVG(File f, int canvasSize) {
    document.ensureDeformed(fields, this, animationTime);
    document.writeSVG(f, canvasSize, colorToHex(themeText));
  }

  void exportPNG(File f, int sizePx) {
    document.ensureDeformed(fields, this, animationTime);
    document.writePNG(f, sizePx, raster, transparentExport, themeBg, themeText);
  }

  String colorToHex(int c) {
    return String.format("#%02X%02X%02X", (c >> 16) & 255, (c >> 8) & 255, c & 255);
  }
}
