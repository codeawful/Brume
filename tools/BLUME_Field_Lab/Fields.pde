class ParamSpec {
  String key, label;
  float minV, maxV;
  ParamSpec(String k, String l, float mn, float mx) {
    key = k; label = l; minV = mn; maxV = mx;
  }
}

abstract class GeometryField {
  String type;
  String displayName;
  boolean enabled = true;
  float mix = 1.0f;
  HashMap<String, Float> params = new HashMap<String, Float>();
  ArrayList<ParamSpec> specs = new ArrayList<ParamSpec>();
  PaintMask mask = new PaintMask(64, 64);

  GeometryField(String t, String n) {
    type = t;
    displayName = n;
  }

  void param(String key, String label, float defaultV, float minV, float maxV) {
    params.put(key, defaultV);
    specs.add(new ParamSpec(key, label, minV, maxV));
  }

  float get(String key) {
    Float v = params.get(key);
    return v == null ? 0 : v.floatValue();
  }

  void set(String key, float v) {
    for (ParamSpec s : specs) {
      if (s.key.equals(key)) {
        params.put(key, constrain(v, s.minV, s.maxV));
        return;
      }
    }
    params.put(key, v);
  }

  abstract PVector apply(PVector current, PVector base, float time);

  JSONObject toJSON() {
    JSONObject j = new JSONObject();
    j.setString("type", type);
    j.setString("name", displayName);
    j.setBoolean("enabled", enabled);
    j.setFloat("mix", mix);
    JSONObject pj = new JSONObject();
    for (String k : params.keySet()) pj.setFloat(k, get(k));
    j.setJSONObject("params", pj);
    j.setJSONObject("mask", mask.toJSON());
    return j;
  }

  void loadJSON(JSONObject j) {
    enabled = j.getBoolean("enabled", true);
    mix = j.getFloat("mix", 1.0f);
    JSONObject pj = j.getJSONObject("params");
    if (pj != null) {
      for (String k : params.keySet()) {
        if (pj.hasKey(k)) set(k, pj.getFloat(k));
      }
    }
    JSONObject mj = j.getJSONObject("mask");
    if (mj != null) mask.fromJSON(mj);
  }

}

GeometryField fieldFromJSON(JSONObject j) {
  if (j == null) return null;
  String t = j.getString("type", "wave");
  GeometryField f = createFieldByType(t);
  if (f != null) f.loadJSON(j);
  return f;
}

GeometryField createFieldByType(String type) {
  if (type.equals("wave")) return new WaveField();
  if (type.equals("slice")) return new SliceField();
  if (type.equals("point")) return new PointField();
  if (type.equals("vortex")) return new VortexField();
  if (type.equals("noise")) return new NoiseField();
  if (type.equals("shear")) return new ShearField();
  if (type.equals("ripple")) return new RippleField();
  return null;
}

class WaveField extends GeometryField {
  WaveField() {
    super("wave", "Wave Field");
    param("amplitude", "Amplitude", 0.07f, -0.30f, 0.30f);
    param("frequency", "Frequency", 8.0f, 0.1f, 40.0f);
    param("phase", "Phase", 0.0f, -PI * 2, PI * 2);
    param("centerY", "Focus Y", 0.50f, 0, 1);
    param("spread", "Spread", 0.20f, 0.02f, 1.0f);
    param("angle", "Direction", 0.0f, -PI, PI);
    param("animate", "Motion", 0.0f, -4.0f, 4.0f);
  }

  PVector apply(PVector current, PVector base, float time) {
    float spread = max(0.001f, get("spread"));
    float d = (base.y - get("centerY")) / spread;
    float envelope = exp(-d * d);
    float phase = get("phase") + time * get("animate");
    float w = sin(base.y * TWO_PI * get("frequency") + phase);
    float a = get("amplitude") * w * envelope;
    float ang = get("angle");
    return current.copy().add(cos(ang) * a, sin(ang) * a);
  }
}

class SliceField extends GeometryField {
  SliceField() {
    super("slice", "Slice Signal");
    param("amplitude", "Amplitude", 0.05f, -0.30f, 0.30f);
    param("bands", "Band Count", 64.0f, 2, 240);
    param("jitter", "Jitter", 0.20f, 0, 1.0f);
    param("centerY", "Focus Y", 0.50f, 0, 1);
    param("spread", "Spread", 0.22f, 0.02f, 1.0f);
    param("seed", "Seed", 1.0f, 0, 999);
  }

  float hash(float n) {
    return fract(sin(n * 12.9898f + get("seed") * 78.233f) * 43758.5453f);
  }
  float fract(float x) { return x - floor(x); }

  PVector apply(PVector current, PVector base, float time) {
    int bands = max(2, round(get("bands")));
    float band = floor(base.y * bands);
    float d = (base.y - get("centerY")) / max(0.001f, get("spread"));
    float env = exp(-d * d);
    float stepped = sin((band / bands) * TWO_PI * 5.0f + get("seed"));
    float rand = (hash(band + 13.0f) * 2.0f - 1.0f) * get("jitter");
    float dx = get("amplitude") * (stepped * (1.0f - get("jitter")) + rand) * env;
    return current.copy().add(dx, 0);
  }
}

class PointField extends GeometryField {
  PointField() {
    super("point", "Point Lens");
    param("strength", "Strength", 0.10f, -0.50f, 0.50f);
    param("centerX", "Center X", 0.65f, 0, 1);
    param("centerY", "Center Y", 0.50f, 0, 1);
    param("radius", "Radius", 0.25f, 0.02f, 1.0f);
    param("falloff", "Falloff", 2.0f, 0.25f, 8.0f);
  }

  PVector apply(PVector current, PVector base, float time) {
    PVector c = new PVector(get("centerX"), get("centerY"));
    PVector delta = PVector.sub(current, c);
    float r = max(0.001f, get("radius"));
    float dist = delta.mag();
    if (dist >= r || dist == 0) return current.copy();
    float f = pow(1.0f - dist / r, get("falloff"));
    delta.normalize().mult(get("strength") * f);
    return current.copy().add(delta);
  }
}

class VortexField extends GeometryField {
  VortexField() {
    super("vortex", "Vortex");
    param("strength", "Rotation", 1.2f, -PI * 2, PI * 2);
    param("centerX", "Center X", 0.68f, 0, 1);
    param("centerY", "Center Y", 0.52f, 0, 1);
    param("radius", "Radius", 0.30f, 0.02f, 1.0f);
    param("falloff", "Falloff", 2.0f, 0.25f, 8.0f);
  }

  PVector apply(PVector current, PVector base, float time) {
    float cx = get("centerX"), cy = get("centerY");
    float dx = current.x - cx, dy = current.y - cy;
    float dist = sqrt(dx * dx + dy * dy);
    float r = max(0.001f, get("radius"));
    if (dist >= r) return current.copy();
    float f = pow(1.0f - dist / r, get("falloff"));
    float a = get("strength") * f;
    float ca = cos(a), sa = sin(a);
    return new PVector(cx + dx * ca - dy * sa, cy + dx * sa + dy * ca);
  }
}

class NoiseField extends GeometryField {
  NoiseField() {
    super("noise", "Noise Warp");
    param("strength", "Strength", 0.035f, 0, 0.25f);
    param("scale", "Scale", 5.0f, 0.1f, 30.0f);
    param("seed", "Seed", 7.0f, 0, 999);
    param("angle", "Bias Angle", 0.0f, -PI, PI);
    param("directionMix", "Directional", 0.30f, 0, 1);
    param("animate", "Motion", 0.0f, -2.0f, 2.0f);
  }

  PVector apply(PVector current, PVector base, float time) {
    float s = get("scale");
    float seed = get("seed") * 0.013f;
    float t = time * get("animate");
    float nx = noise(base.x * s + seed, base.y * s, t + 10.0f) * 2 - 1;
    float ny = noise(base.x * s + seed + 100.0f, base.y * s + 100.0f, t + 30.0f) * 2 - 1;
    PVector organic = new PVector(nx, ny);
    PVector directional = new PVector(cos(get("angle")), sin(get("angle"))).mult(nx);
    PVector d = PVector.lerp(organic, directional, get("directionMix")).mult(get("strength"));
    return current.copy().add(d);
  }
}

class ShearField extends GeometryField {
  ShearField() {
    super("shear", "Local Shear");
    param("strength", "Strength", 0.10f, -0.50f, 0.50f);
    param("centerY", "Focus Y", 0.50f, 0, 1);
    param("spread", "Spread", 0.25f, 0.02f, 1.0f);
    param("slope", "Slope", 1.0f, -4.0f, 4.0f);
  }

  PVector apply(PVector current, PVector base, float time) {
    float d = (base.y - get("centerY")) / max(0.001f, get("spread"));
    float env = exp(-d * d);
    float dx = get("strength") * d * get("slope") * env;
    return current.copy().add(dx, 0);
  }
}

class RippleField extends GeometryField {
  RippleField() {
    super("ripple", "Radial Ripple");
    param("strength", "Strength", 0.045f, -0.25f, 0.25f);
    param("frequency", "Frequency", 18.0f, 1.0f, 60.0f);
    param("phase", "Phase", 0.0f, -PI * 2, PI * 2);
    param("centerX", "Center X", 0.68f, 0, 1);
    param("centerY", "Center Y", 0.50f, 0, 1);
    param("radius", "Radius", 0.40f, 0.02f, 1.2f);
    param("animate", "Motion", 0.0f, -4.0f, 4.0f);
  }

  PVector apply(PVector current, PVector base, float time) {
    PVector c = new PVector(get("centerX"), get("centerY"));
    PVector d = PVector.sub(current, c);
    float dist = d.mag();
    float radius = max(0.001f, get("radius"));
    if (dist == 0 || dist > radius) return current.copy();
    float env = 1.0f - dist / radius;
    float wave = sin(dist * TWO_PI * get("frequency") + get("phase") + time * get("animate"));
    d.normalize().mult(get("strength") * wave * env);
    return current.copy().add(d);
  }
}
