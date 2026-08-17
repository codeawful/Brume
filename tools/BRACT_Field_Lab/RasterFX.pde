class RasterFX {
  boolean enabled = false;
  int ditherMode = 0; // 0 off, 1 Bayer, 2 Atkinson
  float threshold = 0.50f;
  float grain = 0.0f;
  float scanAmount = 0.0f;
  int scanPeriod = 5;
  float scanDuty = 0.65f;

  String ditherName() {
    if (ditherMode == 1) return "BAYER";
    if (ditherMode == 2) return "ATKINSON";
    return "OFF";
  }

  void cycleDither() {
    ditherMode = (ditherMode + 1) % 3;
  }

  PImage apply(PImage source) {
    PImage img = source.copy();
    img.loadPixels();

    if (ditherMode == 2) {
      applyAtkinson(img);
      img.loadPixels();
    }

    int[][] bayer4 = {
      {0, 8, 2, 10},
      {12, 4, 14, 6},
      {3, 11, 1, 9},
      {15, 7, 13, 5}
    };

    for (int y = 0; y < img.height; y++) {
      boolean scanCut = scanAmount > 0 && ((y % max(1, scanPeriod)) / (float)max(1, scanPeriod)) > scanDuty;
      for (int x = 0; x < img.width; x++) {
        int i = y * img.width + x;
        int c = img.pixels[i];
        float a = ((c >>> 24) & 255) / 255.0f;

        if (ditherMode == 1 && a > 0) {
          float t = (bayer4[y & 3][x & 3] + 0.5f) / 16.0f;
          float local = constrain(threshold + (t - 0.5f) * 0.55f, 0, 1);
          a = a >= local ? 1.0f : 0.0f;
        }

        if (scanCut) a *= (1.0f - scanAmount);
        if (grain > 0 && a > 0) {
          float n = random(-grain, grain);
          a = constrain(a + n, 0, 1);
        }

        int alpha = round(a * 255);
        img.pixels[i] = (alpha << 24) | 0x00E8E6E1;
      }
    }
    img.updatePixels();
    return img;
  }

  void applyAtkinson(PImage img) {
    int w = img.width, h = img.height;
    float[] buf = new float[w * h];
    for (int i = 0; i < buf.length; i++) buf[i] = ((img.pixels[i] >>> 24) & 255) / 255.0f;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        int i = y * w + x;
        float oldV = constrain(buf[i], 0, 1);
        float newV = oldV >= threshold ? 1.0f : 0.0f;
        float err = (oldV - newV) / 8.0f;
        buf[i] = newV;
        addErr(buf, w, h, x + 1, y, err);
        addErr(buf, w, h, x + 2, y, err);
        addErr(buf, w, h, x - 1, y + 1, err);
        addErr(buf, w, h, x, y + 1, err);
        addErr(buf, w, h, x + 1, y + 1, err);
        addErr(buf, w, h, x, y + 2, err);
      }
    }
    for (int i = 0; i < buf.length; i++) {
      int a = round(constrain(buf[i], 0, 1) * 255);
      img.pixels[i] = (a << 24) | 0x00E8E6E1;
    }
    img.updatePixels();
  }

  void addErr(float[] b, int w, int h, int x, int y, float e) {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    b[y * w + x] += e;
  }

  JSONObject toJSON() {
    JSONObject j = new JSONObject();
    j.setBoolean("enabled", enabled);
    j.setInt("ditherMode", ditherMode);
    j.setFloat("threshold", threshold);
    j.setFloat("grain", grain);
    j.setFloat("scanAmount", scanAmount);
    j.setInt("scanPeriod", scanPeriod);
    j.setFloat("scanDuty", scanDuty);
    return j;
  }

  void fromJSON(JSONObject j) {
    enabled = j.getBoolean("enabled", enabled);
    ditherMode = j.getInt("ditherMode", ditherMode);
    threshold = j.getFloat("threshold", threshold);
    grain = j.getFloat("grain", grain);
    scanAmount = j.getFloat("scanAmount", scanAmount);
    scanPeriod = j.getInt("scanPeriod", scanPeriod);
    scanDuty = j.getFloat("scanDuty", scanDuty);
  }
}
