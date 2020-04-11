// MIDI UI

class MIDIPage extends UIPage {
  
  public final float inspectorToolbarHeight = 40;
  public float sequencerHeight = 0;
  
  public final static int bars = 4, npb = 4;
  
  public final int maxPatterns = 15;
  
  public static final float beatLength = 0.25;
  
  int scroll = 0;
  
  ArrayList<Pattern> patterns;
  int selectedPattern;
  int patternID;
  
  Sequencer seq;
  
  MIDIPage() {
    super();
    name = "Track";
    patterns = new ArrayList<Pattern>();
    seq = new Sequencer(this);
  }

  void displayInspector(float w, float h) {
    
    if(scroll > patterns.size() - maxPatterns) scroll = patterns.size() - maxPatterns;
    if(scroll < 0) scroll = 0; 
    
    fill(app.navBarColor);
    rect(0, h - inspectorToolbarHeight, w, inspectorToolbarHeight);
    
    fill(app.textColor);
    textSize(28);
    float txtX = w - inspectorToolbarHeight / 2 - textWidth("+") / 2;
    float txtY = h -(textAscent() + textDescent()) / 2 + 2;
    text("-", txtX, txtY);
    text("+", txtX - inspectorToolbarHeight, txtY);
    
    float patternHeight = (h - inspectorToolbarHeight) / maxPatterns;
    if(patterns.size() < maxPatterns) {
      for(int i = 0; i < patterns.size(); i ++) {
        pushMatrix();
        translate(0, i * patternHeight);
        patterns.get(i).displayIcon(w, patternHeight, i == selectedPattern, app.accentColor);
        popMatrix();
      }
    } else {
      for(int i = scroll; i < scroll + maxPatterns; i ++) {
        pushMatrix();
        translate(0, (i - scroll) * patternHeight);
        patterns.get(i).displayIcon(w, patternHeight, i == selectedPattern, app.accentColor);
        popMatrix();
      }
    }
  }
  
  void inspectorClick(float x, float y, float w, float h) {
    if(y > h - inspectorToolbarHeight) {
      if(x > w - inspectorToolbarHeight) {
        minus();
      }
      if(x > w - 2 * inspectorToolbarHeight && x < w - inspectorToolbarHeight) {
        plus();
      }
    } else {
      float patternHeight = (h - inspectorToolbarHeight) / maxPatterns;
      if(patterns.size() < maxPatterns) {
        selectedPattern = min(floor(y / patternHeight), patterns.size() - 1);
      } else {
        selectedPattern = floor(y / patternHeight) - scroll;
      }
    }
  }
  
  void displayMain(float w, float h) {
    sequencerHeight = h / 3 + inspectorToolbarHeight;
    if(patterns.size() == 0) {
      String msg = "Click the + to create a new pattern";
      textSize(18);
      float txtX = (w - textWidth(msg)) / 2;
      float txtY = (h - textAscent() - textDescent()) / 2;
      fill(app.textColor);
      text(msg, txtX, h / 2);
    } else {
      
      Pattern pattern = patterns.get(selectedPattern);
      pattern.displayEditor(w, h - sequencerHeight);
      
      pushMatrix();
      translate(0, h - sequencerHeight);
      fill(app.inspectorColor);
      rect(0, 0, w, sequencerHeight);
      seq.displayEditor(w, sequencerHeight);
      popMatrix();
    }
  }
  
  void mainClick(float x, float y, float w, float h) {
    if(y < h - sequencerHeight) {
      if(patterns.size() > 0) {
        patterns.get(selectedPattern).click(x, y, w, h - sequencerHeight);
      }
    } else {
      seq.click(x, y - (h - sequencerHeight), w, sequencerHeight);
    }
  }
  
  void drag(float x, float y, float w, float h) {
    if(y < h - sequencerHeight) {
      patterns.get(selectedPattern).drag(x, y, w, h - sequencerHeight);
    }
  }
  
  void plus() {
    patternID ++;
    patterns.add(new Pattern("Pattern" + str(patternID)));
    scroll ++;
  }
  
  void minus() {
    if(patterns.size() == 0) return;
    Pattern p = patterns.get(selectedPattern);
    patterns.remove(selectedPattern);
    selectedPattern --;
    if(selectedPattern < 0) selectedPattern = 0;
    seq.removePattern(p);
  }
  
  void keyDown() {
    if(patterns.size() > 0) {
      patterns.get(selectedPattern).keyDown();
    }
    if(key == 's') scroll ++;
    if(key == 'w') scroll --;
  }

  void update() {
    seq.update();
  }

}

class Pattern {
  
  public final String[] noteNames = {"A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#"};
  
  String name;
  ArrayList<Note> notes;
  Note currentNote;
  int pivotTime;
  int id;
  
  int panY = 0;
  
  int bars = MIDIPage.bars, npb = MIDIPage.npb;
  int shownNotes = 17;
  
  Pattern(String name) {
    this.name = name;
    notes = new ArrayList<Note>();
  }
  
  void displayIcon(float w, float h, boolean selected, color c) {
    if(selected) {
      fill(app.accentColor);
      rect(0, 0, 5, h);
    }
    
    if(notes.size() > 1) {
      fill(c);
      int maxNote = -999999999, minNote = 999999999;
      for(Note n : notes) {
        maxNote = max(maxNote, n.note);
        minNote = min(minNote, n.note);
      }
      
      for(Note n : notes) {
        float x = map(n.startTime, 0, MIDIPage.bars * MIDIPage.npb,0, w);
        float y = map(n.note, minNote, maxNote, 2 * h / 3,  h / 3);
        float noteW = map(n.endTime - n.startTime, 0, MIDIPage.bars * MIDIPage.npb, 0, w);
        rect(x, y, noteW, 2);
      }
    } else {
      fill(app.textColor);
      String msg = name;
      float scl = 2 * h / 3;
      while(textWidth(msg) > 3 * w / 3) {
        scl -= 1;
        textSize(scl);
      }
      text(msg, (w - textWidth(msg)) / 2, (h + textAscent() - textDescent()) / 2);
    }
  }
  
  void displayEditor(float w, float h) {
    
    int patternNotes = bars * npb;
    float noteWidth = w / patternNotes;
    float noteHeight = h / shownNotes;
    
    for(int y = 0; y < shownNotes; y ++) {
      if(abs((y + panY) % 2) == 1) {
        fill(app.bgDarkerColor);
        rect(0, y * noteHeight, w, noteHeight);
      }
    }
    
    fill(app.inspectorColor);
    for(int x = 1; x < bars; x ++) {
      rect(x * noteWidth * npb - 1, 0, 2, h);
    }
    
    for(Note n : notes) {
      float x = n.startTime * noteWidth;
      float y = (-n.note - panY) * noteHeight;
      if(-n.note >= panY && -n.note <= panY + shownNotes) {
        fill(app.accentColor);
        rect(x + 2.5, y + 2.5, noteWidth * (n.endTime - n.startTime) - 5, noteHeight - 5);
      }
    }
    
    fill(app.textColor);
    for(int y = 0; y < shownNotes; y ++) {
      int noteIndex = -panY - y;
      while(noteIndex < 0) noteIndex += 12;
      while(noteIndex >= 12) noteIndex -= 12;
      String noteName = noteNames[noteIndex];
      if(noteIndex == 0) {
        int octave = (-panY - y) / 12 + 4;
        noteName += " " + str(octave);
      }
      textSize(noteHeight - 2);
      text(noteName, 10, (y + 1) * noteHeight - 4);
    }
  }
  
  void click(float x, float y, float w, float h) {
    int patternNotes = bars * npb;
    float noteWidth = w / patternNotes;
    float noteHeight = h / shownNotes;
    int nx = floor(x / noteWidth);
    int ny = -floor(y / noteHeight) - panY;
    
    boolean foundNote = false;
    for(Note n : notes) {
      if(n.startTime <= nx && n.endTime > nx && ny == n.note) {
        if(mouseButton == LEFT) {
          foundNote = true;
          currentNote = n;
          if(nx >= (n.startTime + n.endTime) / 2) {
            pivotTime = n.startTime;
          } else {
            pivotTime = n.endTime;
          }
        }
        if(mouseButton == RIGHT) {
          n.deleted = true;
          notes.remove(n);
          return;
        }
      }
    }
    
    if(!foundNote && mouseButton == LEFT) {
      currentNote = new Note(nx, nx + 1, ny);
      notes.add(currentNote);
      pivotTime = nx + 1;
    }
  }
  
  void drag(float x, float y, float w, float h) {
    int patternNotes = bars * npb;
    float noteWidth = w / patternNotes;
    float noteHeight = h / shownNotes;
    int nx = floor(x / noteWidth);
    int ny = -floor(y / noteHeight) - panY;
    
    if(currentNote != null) {
      if(nx >= pivotTime) {
        currentNote.endTime = nx;
      } else {
        currentNote.startTime = nx;
      }
    }
  }
  
  void keyDown() {
    if(keyCode == UP) panY --;
    if(keyCode == DOWN) panY ++;
  }
  
  ArrayList<Note> getNotesAt(int t) {
    ArrayList<Note> result = new ArrayList<Note>();
    for(Note n : notes) {
      if(n.startTime <= t && n.endTime > t) result.add(n);
    }
    return result;
  }
  
}



class Note {
  
  int startTime, endTime;
  int note;
  
  boolean playing = false;
  boolean deleted = false;
  
  Note(int st, int et, int n) {
    startTime = st;
    endTime = et;
    note = n;
  }
  
}
