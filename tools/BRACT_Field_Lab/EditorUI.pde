/*
  Compact UI/controller for BRACT Field Lab.
  ELI5: this file is the dashboard. The geometry math lives elsewhere;
  this class only draws controls and translates mouse/keyboard gestures into edits.
*/

class HitRegion {
  float x, y, w, h, minV, maxV;
  String kind, id;
  HitRegion(float X, float Y, float W, float H, String K, String I) {
    x=X; y=Y; w=W; h=H; kind=K; id=I;
  }
  HitRegion range(float mn, float mx) { minV=mn; maxV=mx; return this; }
  boolean has(float px, float py) { return px>=x && px<=x+w && py>=y && py<=y+h; }
}

class EditorUI {
  PApplet p;
  AppModel app;
  HistoryManager history;
  VariantManager variants;
  ArrayList<HitRegion> hits = new ArrayList<HitRegion>();

  float topH=56, leftW=270, rightW=330, bottomH=50;
  float artX, artY, artSize;
  String activeSlider="", activeText="";
  boolean maskMode=false, sculptMode=false, nodeMode=false;
  boolean dragField=false, dragFocus=false, dragSculpt=false, dragNode=false;
  int nodeContour=-1, nodePoint=-1;
  float lastX, lastY;
  float brushRadius=.075f, brushHardness=.55f, sculptStrength=.85f;

  EditorUI(PApplet parent, AppModel a, HistoryManager h, VariantManager v) {
    p=parent; app=a; history=h; variants=v;
  }

  void layout(int W, int H) {
    float cw=max(120, W-leftW-rightW);
    float ch=max(120, H-topH-bottomH);
    artSize=max(80, min(cw,ch)-56);
    artX=leftW+(cw-artSize)/2;
    artY=topH+(ch-artSize)/2;
  }

  void draw() {
    hits.clear();
    drawTop(); drawLeft(); drawCanvas(); drawRight(); drawBottom();
  }

  void drawTop() {
    noStroke(); fill(app.themePanel); rect(0,0,width,topH);
    stroke(app.themeLine); line(0,topH-1,width,topH-1);
    fill(app.themeText); textAlign(LEFT,CENTER); textSize(13); text("BRACT / FIELD LAB",16,20);
    fill(app.themeMuted); textSize(9); text("GEOMETRY-FIRST LETTERMARK INSTRUMENT",16,38);
    float x=280;
    x=button("FONT","font.load",x,13,58,30)+7;
    x=button("SAVE","preset.save",x,13,58,30)+7;
    x=button("OPEN","preset.load",x,13,58,30)+7;
    x=button("SVG","export.svg",x,13,52,30)+7;
    x=button("PNG","export.png",x,13,52,30)+7;
    x=button("UNDO","history.undo",x,13,58,30)+7;
    x=button("REDO","history.redo",x,13,58,30)+7;
    button(app.animate?"MOTION ON":"MOTION","animate.toggle",x,13,78,30);
  }

  void drawLeft() {
    noStroke(); fill(app.themePanel); rect(0,topH,leftW,height-topH-bottomH);
    stroke(app.themeLine); line(leftW-1,topH,leftW-1,height-bottomH);
    float x=16, w=leftW-32, y=topH+16;
    label("SOURCE",x,y); y+=22;
    drawTextInput("GLYPH",app.document.glyphText,"glyph",x,y,w); y+=48;
    info("FONT",app.document.fontName,x,y); y+=32;
    slider("doc.flattening","OUTLINE DETAIL",app.document.flattening,.15f,4,x,y,w); y+=43;
    button(sculptMode?"SCULPT ON":"SCULPT","sculpt.toggle",x,y,72,26);
    button(nodeMode?"NODES ON":"NODES","nodes.toggle",x+78,y,70,26);
    button("RESET","manual.reset",x+154,y,66,26); y+=39;

    label("PROTECTION",x,y); y+=20;
    slider("app.stemProtect","STEM LOCK",app.stemProtect,0,1,x,y,w); y+=41;
    slider("app.stemWidth","STEM WIDTH",app.stemWidth,.02f,.5f,x,y,w); y+=41;
    slider("app.counterProtect","COUNTER LOCK",app.counterProtect,0,1,x,y,w); y+=41;
    slider("app.maxDisplacement","MAX TRAVEL",app.maxDisplacement,.01f,.5f,x,y,w); y+=41;
    slider("app.globalEffectMix","FIELD MIX",app.globalEffectMix,0,1,x,y,w); y+=47;

    label("FIELD STACK",x,y); y+=20;
    for (int i=0;i<app.fields.size();i++) {
      GeometryField f=app.fields.get(i);
      boolean active=i==app.activeFieldIndex;
      noStroke(); fill(active?color(36,39,44):color(23,24,28)); rect(x,y,w,30,4);
      fill(f.enabled?app.themeText:app.themeMuted); textAlign(LEFT,CENTER); textSize(9);
      text((i+1)+"  "+f.displayName.toUpperCase(),x+9,y+15);
      fill(f.enabled?color(190,202,216):color(70)); ellipse(x+w-13,y+15,7,7);
      hits.add(new HitRegion(x,y,w,30,"button","field.select."+i));
      hits.add(new HitRegion(x+w-30,y,30,30,"button","field.toggle."+i));
      y+=34;
    }
    String[] names={"WAVE","SLICE","POINT","VORTEX","NOISE","SHEAR","RIPPLE"};
    String[] ids={"wave","slice","point","vortex","noise","shear","ripple"};
    for (int i=0;i<ids.length;i++) {
      float bw=(w-6)/2; float bx=x+(i%2)*(bw+6);
      if (i%2==0 && i>0) y+=30;
      button("+ "+names[i],"field.add."+ids[i],bx,y,bw,25);
    }
  }

  void drawCanvas() {
    float canvasX=leftW, canvasY=topH, canvasW=width-leftW-rightW, canvasH=height-topH-bottomH;
    noStroke(); fill(app.themeBg); rect(canvasX,canvasY,canvasW,canvasH);
    stroke(color(40)); noFill(); rect(artX,artY,artSize,artSize);
    stroke(color(30)); line(artX+artSize/2,artY,artX+artSize/2,artY+artSize); line(artX,artY+artSize/2,artX+artSize,artY+artSize/2);
    if (app.document.previewImage!=null) image(app.document.previewImage,artX,artY,artSize,artSize);

    GeometryField f=app.activeField();
    if (f!=null && f.params.containsKey("centerY") && f.params.containsKey("spread")) {
      float cy=artY+f.get("centerY")*artSize, half=f.get("spread")*artSize;
      noStroke(); fill(180,195,215,11); rect(artX,cy-half,artSize,half*2);
      stroke(180,195,215,55); line(artX,cy,artX+artSize,cy);
    }
    if (f!=null && f.params.containsKey("centerX") && f.params.containsKey("centerY")) {
      float hx=artX+f.get("centerX")*artSize, hy=artY+f.get("centerY")*artSize;
      stroke(210); noFill(); ellipse(hx,hy,18,18); line(hx-13,hy,hx+13,hy); line(hx,hy-13,hx,hy+13);
    }
    if (maskMode && f!=null) drawMask(f.mask);
    if (nodeMode) drawNodes();
    if ((sculptMode||maskMode) && insideArt(mouseX,mouseY)) { noFill(); stroke(210,170); ellipse(mouseX,mouseY,brushRadius*artSize*2,brushRadius*artSize*2); }

    fill(app.themeMuted); textAlign(LEFT,TOP); textSize(9);
    String hint="DRAG FIELD CROSSHAIR • SHIFT+DRAG = FOCUS Y • SPACE = BYPASS FIELDS";
    if (sculptMode) hint="SCULPT: DRAG PUSH • SHIFT SMOOTH • ALT/RIGHT RELAX • WHEEL BRUSH SIZE";
    if (maskMode) hint="MASK: DRAG ALLOW • ALT/RIGHT PROTECT • WHEEL BRUSH SIZE";
    if (nodeMode) hint="NODES: DRAG A POINT FOR PRECISE MANUAL EDITING";
    text(hint,artX,artY+artSize+10);
  }

  void drawRight() {
    float x=width-rightW+18, y=topH+16, w=rightW-36;
    noStroke(); fill(app.themePanel); rect(width-rightW,topH,rightW,height-topH-bottomH);
    stroke(app.themeLine); line(width-rightW,topH,width-rightW,height-bottomH);
    label("ACTIVE FIELD",x,y); y+=22;
    GeometryField f=app.activeField();
    if (f==null) { fill(app.themeMuted); textAlign(LEFT,TOP); textSize(10); text("Select or add a field.",x,y); return; }
    fill(app.themeText); textSize(17); textAlign(LEFT,TOP); text(f.displayName.toUpperCase(),x,y); y+=30;
    button(f.enabled?"ENABLED":"DISABLED","active.toggle",x,y,76,25);
    button("DUP","active.duplicate",x+82,y,45,25);
    button("UP","active.up",x+133,y,40,25);
    button("DOWN","active.down",x+179,y,48,25);
    button("X","active.delete",x+233,y,28,25); y+=38;
    slider("field.__mix","FIELD MIX",f.mix,0,1,x,y,w); y+=41;
    for (ParamSpec s:f.specs) { slider("field."+s.key,s.label.toUpperCase(),f.get(s.key),s.minV,s.maxV,x,y,w); y+=41; if (y>height-bottomH-280) break; }

    label("DIRECT TOOLS",x,y); y+=20;
    button(maskMode?"MASK ON":"MASK","mask.toggle",x,y,70,25);
    button("ALL ON","mask.allon",x+76,y,60,25);
    button("ALL OFF","mask.alloff",x+142,y,66,25);
    button("INV","mask.invert",x+214,y,45,25); y+=37;
    slider("ui.brushRadius","BRUSH SIZE",brushRadius,.01f,.25f,x,y,w); y+=41;
    slider("ui.brushHardness","BRUSH HARDNESS",brushHardness,0,.95f,x,y,w); y+=41;
    slider("ui.sculptStrength","SCULPT STRENGTH",sculptStrength,.05f,2,x,y,w); y+=46;

    label("RASTER PREVIEW",x,y); y+=20;
    button(app.raster.enabled?"PREVIEW ON":"PREVIEW OFF","raster.toggle",x,y,88,25);
    button("DITHER "+app.raster.ditherName(),"raster.dither",x+94,y,112,25); y+=36;
    slider("raster.threshold","THRESHOLD",app.raster.threshold,0,1,x,y,w); y+=41;
    slider("raster.scanAmount","SCAN CUT",app.raster.scanAmount,0,1,x,y,w); y+=41;
    slider("raster.grain","GRAIN",app.raster.grain,0,.3f,x,y,w);
  }

  void drawBottom() {
    float y=height-bottomH;
    noStroke(); fill(app.themePanel); rect(0,y,width,bottomH); stroke(app.themeLine); line(0,y,width,y);
    fill(app.themeMuted); textAlign(LEFT,CENTER); textSize(9); text(app.statusMessage,16,y+bottomH/2);
    float x=width-440;
    for (int i=0;i<variants.slots.length;i++) {
      String t=variants.has(i)?"V"+(i+1)+"*":"V"+(i+1);
      button(t,"variant."+i,x+i*52,y+12,44,26);
    }
    fill(app.themeMuted); textAlign(RIGHT,CENTER); text("SHIFT+CLICK V = CAPTURE",width-14,y+bottomH/2);
  }

  float button(String textValue,String id,float x,float y,float w,float h) {
    boolean hot=mouseX>=x&&mouseX<=x+w&&mouseY>=y&&mouseY<=y+h;
    stroke(app.themeLine); fill(hot?color(31,33,38):color(20,21,24)); rect(x,y,w,h,4);
    fill(hot?app.themeText:app.themeMuted); textAlign(CENTER,CENTER); textSize(9); text(textValue,x+w/2,y+h/2);
    hits.add(new HitRegion(x,y,w,h,"button",id)); return x+w;
  }

  void label(String s,float x,float y) { fill(color(105,110,119)); textAlign(LEFT,TOP); textSize(9); text(s,x,y); }
  void info(String k,String v,float x,float y) { label(k,x,y); fill(app.themeText); textSize(10); text(shorten(v,30),x,y+14); }
  String shorten(String s,int n) { if (s==null) return ""; return s.length()<=n?s:s.substring(0,n-1)+"…"; }

  void drawTextInput(String labelText,String value,String id,float x,float y,float w) {
    label(labelText,x,y); float yy=y+14;
    stroke(activeText.equals(id)?color(165,177,193):app.themeLine); fill(color(10,11,13)); rect(x,yy,w,27,4);
    fill(app.themeText); textAlign(LEFT,CENTER); textSize(12); text(value,x+8,yy+13);
    hits.add(new HitRegion(x,yy,w,27,"text",id));
  }

  void slider(String id,String labelText,float value,float mn,float mx,float x,float y,float w) {
    label(labelText,x,y); fill(app.themeMuted); textAlign(RIGHT,TOP); textSize(8); text(nf(value,0,3),x+w,y);
    float yy=y+19; stroke(app.themeLine); line(x,yy,x+w,yy);
    float t=(value-mn)/(mx-mn); float kx=x+constrain(t,0,1)*w;
    stroke(color(180,192,207)); line(x,yy,kx,yy); noStroke(); fill(color(215,220,226)); ellipse(kx,yy,8,8);
    hits.add(new HitRegion(x-4,yy-9,w+8,18,"slider",id).range(mn,mx));
  }

  boolean insideArt(float x,float y) { return x>=artX&&x<=artX+artSize&&y>=artY&&y<=artY+artSize; }

  void drawMask(PaintMask m) {
    float cw=artSize/m.w, ch=artSize/m.h;
    noStroke();
    for (int yy=0;yy<m.h;yy+=2) for (int xx=0;xx<m.w;xx+=2) {
      float protect=1-m.values[yy*m.w+xx]; if (protect<.05f) continue;
      fill(255,90,90,70*protect); rect(artX+xx*cw,artY+yy*ch,cw*2.2f,ch*2.2f);
    }
  }

  void drawNodes() {
    for (int ci=0;ci<app.document.contours.size();ci++) {
      GlyphContour c=app.document.contours.get(ci);
      for (int pi=0;pi<c.points.size();pi++) {
        PVector q=app.document.manualSource(c.points.get(pi));
        float x=artX+q.x*artSize, y=artY+q.y*artSize;
        boolean sel=ci==nodeContour&&pi==nodePoint;
        noStroke(); fill(sel?color(255,210,120):(c.hole?color(140,175,215):color(220,150))); ellipse(x,y,sel?8:4,sel?8:4);
      }
    }
  }

  HitRegion hit(float x,float y) { for (int i=hits.size()-1;i>=0;i--) if (hits.get(i).has(x,y)) return hits.get(i); return null; }

  void mousePressed(float mx,float my,int buttonCode) {
    activeText="";
    if ((sculptMode||maskMode||nodeMode)&&insideArt(mx,my)) {
      if (sculptMode) { history.commit("Before sculpt"); dragSculpt=true; lastX=mx; lastY=my; sculptGesture(mx,my,0,0,buttonCode); return; }
      if (maskMode && app.activeField()!=null) { history.commit("Before mask"); paintMask(mx,my,buttonCode); return; }
      if (nodeMode && selectNode(mx,my)) { history.commit("Before node move"); dragNode=true; return; }
    }
    GeometryField f=app.activeField();
    if (insideArt(mx,my) && f!=null) {
      if (p.keyPressed && p.keyCode==SHIFT && f.params.containsKey("centerY")) { dragFocus=true; setFocus(my); return; }
      if (f.params.containsKey("centerX")&&f.params.containsKey("centerY")) {
        float hx=artX+f.get("centerX")*artSize, hy=artY+f.get("centerY")*artSize;
        if (dist(mx,my,hx,hy)<30) { history.commit("Before field move"); dragField=true; setCenter(mx,my); return; }
      }
    }
    HitRegion h=hit(mx,my); if (h==null) return;
    if (h.kind.equals("text")) { activeText=h.id; return; }
    if (h.kind.equals("slider")) { activeSlider=h.id; history.commit("Before slider"); updateSlider(mx,h); return; }
    if (h.kind.equals("button")) action(h.id);
  }

  void mouseDragged(float mx,float my,int buttonCode) {
    if (dragSculpt) { float dx=(mx-lastX)/artSize, dy=(my-lastY)/artSize; sculptGesture(mx,my,dx,dy,buttonCode); lastX=mx; lastY=my; return; }
    if (dragNode) { moveNode(mx,my); return; }
    if (maskMode && insideArt(mx,my) && app.activeField()!=null) { paintMask(mx,my,buttonCode); return; }
    if (dragField) { setCenter(mx,my); return; }
    if (dragFocus) { setFocus(my); return; }
    if (!activeSlider.equals("")) { for (HitRegion h:hits) if (h.kind.equals("slider")&&h.id.equals(activeSlider)) { updateSlider(mx,h); break; } }
  }

  void mouseReleased(float mx,float my,int buttonCode) {
    if (!activeSlider.equals("")||dragField||dragFocus||dragSculpt||dragNode||maskMode) history.commit("Edit");
    activeSlider=""; dragField=false; dragFocus=false; dragSculpt=false; dragNode=false;
  }

  void mouseWheel(float amount,float mx,float my) {
    if ((sculptMode||maskMode)&&insideArt(mx,my)) brushRadius=constrain(brushRadius-amount*.008f,.01f,.25f);
  }

  void keyPressed(char k,int code) {
    if (!activeText.equals("")) {
      if (code==ESC||code==ENTER||code==RETURN) { activeText=""; return; }
      if (code==BACKSPACE && app.document.glyphText.length()>0) { String s=app.document.glyphText; app.document.setGlyph(s.substring(0,max(0,s.length()-1))); app.markDirty(); return; }
      return;
    }
    if (k==' ') { app.previewBypass=true; app.markDirty(); }
    else if (k=='f'||k=='F') selectInput("Choose a .ttf or .otf font","fontFileSelected");
    else if (k=='s'||k=='S') { sculptMode=!sculptMode; maskMode=false; nodeMode=false; }
    else if (k=='n'||k=='N') { nodeMode=!nodeMode; sculptMode=false; maskMode=false; }
    else if (k=='m'||k=='M') { maskMode=!maskMode; sculptMode=false; nodeMode=false; }
    else if (k=='a'||k=='A') { app.animate=!app.animate; app.markDirty(); }
    else if (k=='r'||k=='R') randomize();
    else if (k=='p'||k=='P') selectOutput("Save BRACT preset","presetOutputSelected");
    else if (k=='l'||k=='L') selectInput("Open BRACT preset","presetFileSelected");
    else if (k=='z'||k=='Z') history.undo();
    else if (k=='y'||k=='Y') history.redo();
    else if (k>='1'&&k<='6') variants.recall((int)(k-'1'));
    else if (code==DELETE && app.activeFieldIndex>=0) { app.removeField(app.activeFieldIndex); history.commit("Delete field"); }
  }

  void keyTyped(char k) {
    if (!activeText.equals("glyph")) return;
    if (k==BACKSPACE||k==DELETE||k==ENTER||k==RETURN||k==ESC||k==TAB) return;
    String next=app.document.glyphText+k;
    if (next.codePointCount(0,next.length())<=8) { app.document.setGlyph(next); app.markDirty(); history.commit("Glyph edit"); }
  }

  void keyReleased(char k,int code) { if (k==' ') { app.previewBypass=false; app.markDirty(); } }

  void action(String id) {
    if (id.equals("font.load")) selectInput("Choose a .ttf or .otf font","fontFileSelected");
    else if (id.equals("preset.save")) selectOutput("Save BRACT preset","presetOutputSelected");
    else if (id.equals("preset.load")) selectInput("Open BRACT preset","presetFileSelected");
    else if (id.equals("export.svg")) selectOutput("Export vector SVG","svgOutputSelected");
    else if (id.equals("export.png")) selectOutput("Export PNG","pngOutputSelected");
    else if (id.equals("history.undo")) history.undo();
    else if (id.equals("history.redo")) history.redo();
    else if (id.equals("animate.toggle")) { app.animate=!app.animate; app.markDirty(); }
    else if (id.equals("sculpt.toggle")) { sculptMode=!sculptMode; maskMode=false; nodeMode=false; }
    else if (id.equals("nodes.toggle")) { nodeMode=!nodeMode; sculptMode=false; maskMode=false; }
    else if (id.equals("manual.reset")) { app.document.clearManualEdits(); app.markDirty(); history.commit("Reset form"); }
    else if (id.startsWith("field.add.")) { app.addField(createFieldByType(id.substring(10))); history.commit("Add field"); }
    else if (id.startsWith("field.select.")) app.activeFieldIndex=parseIndex(id);
    else if (id.startsWith("field.toggle.")) { int i=parseIndex(id); if (i>=0&&i<app.fields.size()) { app.fields.get(i).enabled=!app.fields.get(i).enabled; app.markDirty(); } }
    else if (id.equals("active.toggle")&&app.activeField()!=null) { app.activeField().enabled=!app.activeField().enabled; app.markDirty(); }
    else if (id.equals("active.duplicate")) app.duplicateActiveField();
    else if (id.equals("active.up")) app.moveField(app.activeFieldIndex,-1);
    else if (id.equals("active.down")) app.moveField(app.activeFieldIndex,1);
    else if (id.equals("active.delete")) app.removeField(app.activeFieldIndex);
    else if (id.equals("mask.toggle")) { maskMode=!maskMode; sculptMode=false; nodeMode=false; }
    else if (id.equals("mask.allon")&&app.activeField()!=null) { app.activeField().mask.clear(1); app.markDirty(); }
    else if (id.equals("mask.alloff")&&app.activeField()!=null) { app.activeField().mask.clear(0); app.markDirty(); }
    else if (id.equals("mask.invert")&&app.activeField()!=null) { app.activeField().mask.invert(); app.markDirty(); }
    else if (id.equals("raster.toggle")) { app.raster.enabled=!app.raster.enabled; app.markDirty(); }
    else if (id.equals("raster.dither")) { app.raster.cycleDither(); app.raster.enabled=true; app.markDirty(); }
    else if (id.startsWith("variant.")) { int i=parseIndex(id); if (p.keyPressed&&p.keyCode==SHIFT) variants.capture(i); else variants.recall(i); }
  }

  int parseIndex(String id) { int d=id.lastIndexOf('.'); try { return Integer.parseInt(id.substring(d+1)); } catch(Exception e) { return -1; } }

  void updateSlider(float mx,HitRegion h) { float t=constrain((mx-h.x)/h.w,0,1); setValue(h.id,lerp(h.minV,h.maxV,t)); app.markDirty(); }

  void setValue(String id,float v) {
    if (id.equals("doc.flattening")) { app.document.flattening=v; app.document.rebuild(); }
    else if (id.equals("app.stemProtect")) app.stemProtect=v;
    else if (id.equals("app.stemWidth")) app.stemWidth=v;
    else if (id.equals("app.counterProtect")) app.counterProtect=v;
    else if (id.equals("app.maxDisplacement")) app.maxDisplacement=v;
    else if (id.equals("app.globalEffectMix")) app.globalEffectMix=v;
    else if (id.equals("ui.brushRadius")) brushRadius=v;
    else if (id.equals("ui.brushHardness")) brushHardness=v;
    else if (id.equals("ui.sculptStrength")) sculptStrength=v;
    else if (id.equals("raster.threshold")) app.raster.threshold=v;
    else if (id.equals("raster.scanAmount")) { app.raster.scanAmount=v; app.raster.enabled=true; }
    else if (id.equals("raster.grain")) { app.raster.grain=v; app.raster.enabled=true; }
    else if (id.equals("field.__mix")&&app.activeField()!=null) app.activeField().mix=v;
    else if (id.startsWith("field.")&&app.activeField()!=null) app.activeField().set(id.substring(6),v);
  }

  void setCenter(float mx,float my) { GeometryField f=app.activeField(); if (f==null) return; f.set("centerX",constrain((mx-artX)/artSize,0,1)); f.set("centerY",constrain((my-artY)/artSize,0,1)); app.markDirty(); }
  void setFocus(float my) { GeometryField f=app.activeField(); if (f==null||!f.params.containsKey("centerY")) return; f.set("centerY",constrain((my-artY)/artSize,0,1)); app.markDirty(); }

  void paintMask(float mx,float my,int buttonCode) {
    GeometryField f=app.activeField(); if (f==null) return;
    float u=constrain((mx-artX)/artSize,0,1), v=constrain((my-artY)/artSize,0,1);
    float target=(buttonCode==RIGHT||(p.keyPressed&&p.keyCode==ALT))?0:1;
    f.mask.paint(u,v,brushRadius,brushHardness,target); app.markDirty();
  }

  boolean selectNode(float mx,float my) {
    float best=18; nodeContour=-1; nodePoint=-1;
    for (int ci=0;ci<app.document.contours.size();ci++) {
      GlyphContour c=app.document.contours.get(ci);
      for (int pi=0;pi<c.points.size();pi++) {
        PVector q=app.document.manualSource(c.points.get(pi)); float px=artX+q.x*artSize, py=artY+q.y*artSize;
        float d=dist(mx,my,px,py); if (d<best) { best=d; nodeContour=ci; nodePoint=pi; }
      }
    }
    return nodeContour>=0;
  }

  void moveNode(float mx,float my) {
    if (nodeContour<0||nodePoint<0) return; GlyphPoint gp=app.document.contours.get(nodeContour).points.get(nodePoint);
    float nx=constrain((mx-artX)/artSize,-.5f,1.5f), ny=constrain((my-artY)/artSize,-.5f,1.5f);
    gp.manual.set(nx-gp.base.x,ny-gp.base.y); app.markDirty();
  }

  void sculptGesture(float mx,float my,float dx,float dy,int buttonCode) {
    boolean relax=buttonCode==RIGHT||(p.keyPressed&&p.keyCode==ALT);
    if (p.keyPressed&&p.keyCode==SHIFT) smoothAt(mx,my); else sculptAt(mx,my,dx,dy,relax);
  }

  void sculptAt(float mx,float my,float dx,float dy,boolean relax) {
    float rr=brushRadius*artSize;
    for (GlyphContour c:app.document.contours) for (GlyphPoint gp:c.points) {
      PVector q=app.document.manualSource(gp); float px=artX+q.x*artSize, py=artY+q.y*artSize, d=dist(mx,my,px,py); if (d>rr) continue;
      float w=1-constrain(d/max(1,rr),0,1); w=w*w*(3-2*w); w=pow(w,lerp(2.5f,.55f,brushHardness));
      if (relax) gp.manual.mult(max(0,1-w*.12f*sculptStrength)); else gp.manual.add(dx*w*sculptStrength,dy*w*sculptStrength);
    }
    app.markDirty();
  }

  void smoothAt(float mx,float my) {
    float rr=brushRadius*artSize;
    for (GlyphContour c:app.document.contours) {
      int n=c.points.size(); if (n<3) continue; PVector[] old=new PVector[n]; for (int i=0;i<n;i++) old[i]=c.points.get(i).manual.copy();
      for (int i=0;i<n;i++) {
        GlyphPoint gp=c.points.get(i); PVector q=app.document.manualSource(gp); float d=dist(mx,my,artX+q.x*artSize,artY+q.y*artSize); if (d>rr) continue;
        float w=1-constrain(d/max(1,rr),0,1); w=w*w*(3-2*w); PVector avg=PVector.add(old[(i-1+n)%n],old[i]); avg.add(old[(i+1)%n]).div(3);
        gp.manual.set(PVector.lerp(old[i],avg,constrain(w*.28f*sculptStrength,0,1)));
      }
    }
    app.markDirty();
  }

  void randomize() {
    GeometryField f=app.activeField(); if (f==null) return; history.commit("Before randomize");
    for (ParamSpec s:f.specs) { float range=(s.maxV-s.minV)*.18f; f.set(s.key,constrain(f.get(s.key)+random(-range,range),s.minV,s.maxV)); }
    app.markDirty(); history.commit("Randomize field");
  }
}
