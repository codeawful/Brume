class HistoryManager {
  AppModel app;
  int capacity;
  ArrayList<String> states = new ArrayList<String>();
  ArrayList<String> labels = new ArrayList<String>();
  int cursor = -1;

  HistoryManager(AppModel a, int cap) {
    app = a; capacity = cap;
  }

  String serialize() {
    return app.toJSON().toString();
  }

  void reset() {
    states.clear(); labels.clear(); cursor = -1;
    commit("Initial");
  }

  void commit(String label) {
    String s = serialize();
    if (cursor >= 0 && states.get(cursor).equals(s)) return;
    while (states.size() > cursor + 1) {
      states.remove(states.size() - 1);
      labels.remove(labels.size() - 1);
    }
    states.add(s); labels.add(label); cursor++;
    while (states.size() > capacity) {
      states.remove(0); labels.remove(0); cursor--;
    }
  }

  boolean canUndo() { return cursor > 0; }
  boolean canRedo() { return cursor >= 0 && cursor < states.size() - 1; }

  void undo() {
    if (!canUndo()) return;
    cursor--;
    app.fromJSON(parseJSONObject(states.get(cursor)));
    app.status("Undo: " + labels.get(cursor));
  }

  void redo() {
    if (!canRedo()) return;
    cursor++;
    app.fromJSON(parseJSONObject(states.get(cursor)));
    app.status("Redo: " + labels.get(cursor));
  }
}

class VariantManager {
  AppModel app;
  String[] slots;

  VariantManager(AppModel a, int count) {
    app = a;
    slots = new String[count];
  }

  void capture(int i) {
    if (i < 0 || i >= slots.length) return;
    slots[i] = app.toJSON().toString();
    app.status("Captured variant " + (i + 1));
  }

  void recall(int i) {
    if (i < 0 || i >= slots.length || slots[i] == null) return;
    app.fromJSON(parseJSONObject(slots[i]));
    app.status("Recalled variant " + (i + 1));
  }

  boolean has(int i) {
    return i >= 0 && i < slots.length && slots[i] != null;
  }
}
