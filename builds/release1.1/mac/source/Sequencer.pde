// Sequencer UI

class Sequencer {
  
  MIDIPage midi;
  ArrayList<SequencePattern> patterns;
  
  AudioRecorder recorder;
  boolean recording;
  
  public final int horizPatterns = 10;
  int vertPatterns = 5;
  
  int selectedInst;
  int scrollX;
  
  float time;
  
  boolean isPaused = false;
  
  boolean loopingPattern;
  int patternID;
  
  Sequencer(MIDIPage midi) {
    this.midi = midi;
    patterns = new ArrayList<SequencePattern>();
    sequencer = this;
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
    
    int maxY = -1;
    for(SequencePattern p : patterns) {
      if(p.time >= scrollX && p.time < scrollX + horizPatterns) {
        float x = map(p.time - scrollX, 0, horizPatterns, 0, w);
        float y = map(p.y, 0, vertPatterns, 0, h - midi.inspectorToolbarHeight);
        pushMatrix();
        translate(x, y);
        p.p.displayIcon(iconWidth, iconHeight, false, p.getColor());
        popMatrix();
      }
      maxY = max(maxY, p.y);
    }
    vertPatterns = min(max(maxY + 2, 5), 10);
    
    for(int x = scrollX; x < scrollX + horizPatterns; x ++) {
      if(loopingPattern && x != patternID) {
        fill(0, 0, 0, 100);
        rect(x * iconWidth, 0, iconWidth, h - midi.inspectorToolbarHeight);
      }
    }
    
    
    float tx = iconWidth * (time / patternDuration - scrollX);
    if(tx < w - 1) {
      fill(app.textColor);
      rect(tx,  0, 2, h - midi.inspectorToolbarHeight);
    }
    
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
      
      int mx = floor(x / iconWidth) + scrollX;
      int my = floor(y / iconHeight);
      
      boolean found = false;
      for(SequencePattern p : patterns) {
        if(p.time == mx && p.y == my) {
          found = true;
          if(mouseButton == RIGHT) {
            p.p.delete();
            patterns.remove(p);
            return;
          }
        }
      }
      
      if(app.shift) {
        if(mouseButton == LEFT) {
          patternID = mx;
          loopingPattern = true;
        }
        if(mouseButton == RIGHT) {
          loopingPattern = false;
        }
      }
      
      if(!found && mouseButton == LEFT && !app.shift) {
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
    
    float patternDuration = (midi.beatLength * midi.bars * midi.npb);
    int currentPatternTime = floor(time / patternDuration);
    int currentBeat = floor((time % patternDuration) / midi.beatLength);
    
    if (!isPaused) {
      time += delta;
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
      if(time > (maxTime + 1) * patternDuration) {
        if(recording) {
          recorder.endRecord();
          recording = false;
          recorder.save();
          app.disableControlls = false;
        }
        time = 0;
      }
      if(loopingPattern) {
        if(time < patternID * patternDuration) time = patternID * patternDuration;
        if(time > (patternID + 1) * patternDuration) time = patternID * patternDuration;
      }
    }
    for(int i = patterns.size() - 1; i >= 0; i --) {
      if(patterns.get(i).shouldRemove()) patterns.remove(i);
    }
    
  }
  
  public void togglePause() {
   this.isPaused = !this.isPaused; 
  }
  
  ArrayList<String> getData() {
    ArrayList<String> result = new ArrayList<String>();
    for(SequencePattern p : patterns) result.add(p.toString());
    return result;
  }
  
  void load(ArrayList<String> data) {
    patterns = new ArrayList<SequencePattern>();
    for(String line : data) {
      SequencePattern pattern = new SequencePattern(line, midi);
      patterns.add(pattern);
    }
  }
  
  void export(String path) {
    if(patterns.size() == 0) return;
    recorder = minim.createRecorder(audioOut, dataPath(path + ".wav"));
    recorder.beginRecord();
    time = 0;
    app.disableControlls = true;
    recording = true;
    isPaused = false;
    for(Instrument inst : instPage.instruments) {
      inst.stopAll();
    }
  }
  
  void keyDown() {
    if(keyCode == RIGHT) scrollX ++;
    if(keyCode == LEFT) scrollX = max(0, scrollX - 1);
    
    if(key == 'l') {
      float patternDuration = (midi.beatLength * midi.bars * midi.npb);
      int currentTime = floor(time / patternDuration);
      time = (currentTime + 1) * patternDuration;
    }
    if(key == 'j') {
      float patternDuration = (midi.beatLength * midi.bars * midi.npb);
      int currentTime = floor(time / patternDuration);
      time = (currentTime - 1) * patternDuration;
    }
  }
  
}


class SequencePattern {
  
  String instName;
  int instID;
  Pattern p;
  int time;
  int y;
  
  SequencePattern(String line, MIDIPage midi) {
    String[] parts = line.split(",");
    p = midi.patterns.get(int(parts[0]));
    instID = int(parts[1]);
    instName = parts[2];
    time = int(parts[3]);
    y = int(parts[4]);
  }
  
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
  
  String toString() {
    return str(p.index) + "," + str(instID) + "," + instName + "," + str(time) + "," + str(y);
  }
  
}
