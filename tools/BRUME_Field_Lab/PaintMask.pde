class PaintMask {
  int w, h;
  float[] values;

  PaintMask(int width, int height) {
    w = width;
    h = height;
    values = new float[w * h];
    clear(1.0f); // White = field is allowed everywhere.
  }

  void clear(float value) {
    for (int i = 0; i < values.length; i++) values[i] = value;
  }

  void invert() {
    for (int i = 0; i < values.length; i++) values[i] = 1.0f - values[i];
  }

  float sample(float u, float v) {
    u = constrain(u, 0, 1);
    v = constrain(v, 0, 1);
    float x = u * (w - 1);
    float y = v * (h - 1);
    int x0 = floor(x), y0 = floor(y);
    int x1 = min(w - 1, x0 + 1), y1 = min(h - 1, y0 + 1);
    float tx = x - x0, ty = y - y0;
    float a = lerp(values[y0 * w + x0], values[y0 * w + x1], tx);
    float b = lerp(values[y1 * w + x0], values[y1 * w + x1], tx);
    return lerp(a, b, ty);
  }

  void paint(float u, float v, float radius, float hardness, float target) {
    float cx = u * (w - 1);
    float cy = v * (h - 1);
    float rr = max(1, radius * max(w, h));
    int minX = max(0, floor(cx - rr));
    int maxX = min(w - 1, ceil(cx + rr));
    int minY = max(0, floor(cy - rr));
    int maxY = min(h - 1, ceil(cy + rr));

    for (int y = minY; y <= maxY; y++) {
      for (int x = minX; x <= maxX; x++) {
        float d = dist(x, y, cx, cy) / rr;
        if (d > 1) continue;
        float inner = constrain(hardness, 0, 0.999f);
        float alpha = d <= inner ? 1.0f : 1.0f - (d - inner) / (1.0f - inner);
        int idx = y * w + x;
        values[idx] = lerp(values[idx], target, constrain(alpha * 0.34f, 0, 1));
      }
    }
  }

  JSONObject toJSON() {
    JSONObject j = new JSONObject();
    j.setInt("w", w);
    j.setInt("h", h);
    JSONArray a = new JSONArray();
    for (int i = 0; i < values.length; i++) a.setInt(i, round(constrain(values[i], 0, 1) * 255));
    j.setJSONArray("values", a);
    return j;
  }

  void fromJSON(JSONObject j) {
    int nw = j.getInt("w", w);
    int nh = j.getInt("h", h);
    JSONArray a = j.getJSONArray("values");
    if (a == null) return;
    w = nw; h = nh;
    values = new float[w * h];
    int count = min(values.length, a.size());
    for (int i = 0; i < count; i++) values[i] = a.getInt(i) / 255.0f;
    for (int i = count; i < values.length; i++) values[i] = 1.0f;
  }
}
