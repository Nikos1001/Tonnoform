// Sequencer UI

class Sequencer {
  
  MIDIPage midi;
  ArrayList<SequencePattern> patterns;
  
  public final int horizPatterns = 10;
  public final int vertPatterns = 5;
  
  int selectedInst;
  
  float time;
  
  boolean isPaused = false;
  
  Sequencer(MIDIPage midi) {
    this.midi = midi;
    patterns = new ArrayList<SequencePattern>();
  }
  
  void displayEditor(float w, float h) {
    
    float patternDuration = (midi.beatLength * midi.bars * midi.npb);
    
    // Sequence
    float iconWidth = w / horizPatterns;
    float iconHeight = (h - midi.inspectorToolbarHeight) / vertPatterns;
    
    for(int y = 0; y < vertPatterns; y ++) {
      if(y % 2 == 0) {
        fill(app.darkInspectorColor);
        rect(0, y * iconHeight, w, iconHeight);
      }
    }
    for(int x = 1; x < horizPatterns; x ++) {
      fill(app.navBarColor);
      rect(x * iconWidth - 1.5, 0, 3, h - midi.inspectorToolbarHeight);
    }
    
    for(SequencePattern p : patterns) {
      float x = map(p.time, 0, horizPatterns, 0, w);
      float y = map(p.y, 0, vertPatterns, 0, h - midi.inspectorToolbarHeight);
      pushMatrix();
      translate(x, y);
      p.p.displayIcon(iconWidth, iconHeight, false, p.getColor());
      popMatrix();
    }
    
    fill(app.textColor);
    rect(iconWidth * time / patternDuration,  0, 2, h - midi.inspectorToolbarHeight);
    
    // Toolbar
    pushMatrix();
    translate(0, h - midi.inspectorToolbarHeight);
    fill(app.navBarColor);
    rect(0, 0, w, midi.inspectorToolbarHeight);
    
    fill(app.textColor);
    textSize(16);
    text(instPage.instruments.get(selectedInst).name, 15, midi.inspectorToolbarHeight / 2 + 8);
    fill(instPage.instruments.get(selectedInst).getColor());
    rect(0, 0, 5, midi.inspectorToolbarHeight);
    
    popMatrix();
  }
  
  void click(float x, float y, float w, float h) {
    if(y < h - midi.inspectorToolbarHeight) {
      float iconWidth = w / horizPatterns;
      float iconHeight = (h - midi.inspectorToolbarHeight) / vertPatterns;
      
      int mx = floor(x / iconWidth);
      int my = floor(y / iconHeight);
      
      boolean found = false;
      for(SequencePattern p : patterns) {
        if(p.time == mx && p.y == my) {
          found = true;
          if(mouseButton == RIGHT) {
            patterns.remove(p);
            return;
          }
        }
      }
      
      if(!found && mouseButton == LEFT) {
        patterns.add(new SequencePattern(midi.patterns.get(midi.selectedPattern), mx, my, selectedInst));
      }
    } else {
      if(x < 15 + textWidth(instPage.instruments.get(selectedInst).name)) {
        selectedInst ++;
        if(selectedInst > instPage.instruments.size() - 1) selectedInst = 0;
      }
    }
  }
  
  void removePattern(Pattern p) {
    for(int i = patterns.size() - 1; i >= 0; i --) {
      if(patterns.get(i).p.name.equals(p.name)) {
        patterns.remove(i);
      }
    }
  }
  
  void update() {
    time += delta;
    if (this.isPaused) {
      time = 0;
      return; 
    }
    for(int i = patterns.size() - 1; i >= 0; i --) {
      if(patterns.get(i).shouldRemove()) patterns.remove(i);
    }
    
    float patternDuration = (midi.beatLength * midi.bars * midi.npb);
    int currentPatternTime = floor(time / patternDuration);
    int currentBeat = floor((time % patternDuration) / midi.beatLength);
    
    int maxTime = -999;
    for(SequencePattern p : patterns) {
      if(p.time == currentPatternTime) {
        ArrayList<Note> notes = p.p.getNotesAt(currentBeat);
        for(Note n : notes) {
          p.getInst().playNote(n);
        }
      }
      maxTime = max(p.time, maxTime);
    }
    if(time > (maxTime + 1) * patternDuration) time = 0;
  }
  
  public void togglePause() {
   this.isPaused = !this.isPaused; 
  }
  
}


class SequencePattern {
  
  String instName;
  int instID;
  Pattern p;
  int time;
  int y;
  
  SequencePattern(Pattern p, int t, int y, int instID) {
    this.p = p;
    time = t;
    this.y = y;
    this.instID = instID;
    instName = instPage.instruments.get(instID).name;
  }
  
  boolean shouldRemove() {
    return !instPage.instruments.get(instID).name.equals(instName);
  }
  
  color getColor() {
    colorMode(HSB);
    color c = color(map(getInst().hue, 0, 360, 0, 255), 125, 255);
    colorMode(RGB);
    return c;
  }
  
  Instrument getInst() {
    return instPage.instruments.get(instID);
  }
  
}
