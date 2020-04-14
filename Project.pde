

class ProjectPage extends UIPage {
  
  int bpm = 240;
  int bars = 4;
  int npb = 4;
  
  ProjectPage() {
    super();
    name = "Project";
  }
  
  void displayInspector(float w, float h) {
    fill(app.textColor);
    textSize(16);
    text("Save Project", 10, 20);
    text("Load Project", 10, 40);
    text("Export WAV", 10, 60);
    text("Export Instrument Bundle", 10, 80);
    text("Import Instrument Bundle", 10, 100);
    
    String msg = "-   BPM: " + str(bpm) + "   +";
    text(msg, (w - textWidth(msg)) / 2, h - 40);
    msg = "-   Bars: " + str(bars) + "   +";
    text(msg, (w - textWidth(msg)) / 2, h - 20);
    msg = "-   Notes per bar: " + str(npb) + "   +";
    text(msg, (w - textWidth(msg)) / 2, h - 2);
  }
  
  void inspectorClick(float x, float y, float w, float h) {
    if(y < 20) {
      selectOutput("Choose location to save", "saveDialog");
    }
    if(y > 20 && y < 40) {
      selectInput("Choose file to open", "openDialog");
    }
    if(y > 40 && y < 60) {
      selectOutput("Choose location to expot", "exportDialog");
    }
    if(y > 60 && y <  80) {
      selectOutput("Choose location to export", "exportInstDialog");
    }
    if(y > 80 && y < 100) {
      selectInput("Choose file to import", "importInstDialog");
    }
    
    if(y > h - 60 && y < h - 40) {
      if(x > w / 2) {
        bpm += 10;
      } else {
        bpm = max(10, bpm - 10);
      }
    }
    if(y > h - 40 && y < h - 20) {
      if(x > w / 2) {
        bars ++;
      } else {
        bars = max(1, bars - 1);
      }
    }
    if(y > h - 20) {
      if(x > w / 2) {
        npb ++;
      } else {
        npb = max(1, npb - 1);
      }
    }
    
    
  }
  
  ArrayList<String> getData() {
    ArrayList<String> data = new ArrayList<String>();
    data.add(str(bpm));
    data.add(str(bars));
    data.add(str(npb));
    return data;
  }
  
  void load(ArrayList<String> data) {
    bpm = int(data.get(0));
    bars = int(data.get(1));
    npb = int(data.get(2));
  }
  
}

String filePath = "";


void saveDialog(File f) {
  if(f == null) return;
  filePath = f.getAbsolutePath();
  setAppTitle("Tonnoform " + filePath + ".tnfproj");
  app.save(f.getAbsolutePath());
}

void openDialog(File f) {
  if(f == null) return;
  filePath = f.getAbsolutePath();
  setAppTitle("Tonnoform " + filePath);
  app.load(f.getAbsolutePath());
}

void exportDialog(File f) {
  if(f == null) return;
  sequencer.export(f.getAbsolutePath());
}

void exportInstDialog(File f) {
  if(f == null) return;
  instPage.exportBundle(f.getAbsolutePath());
}

void importInstDialog(File f) {
  if(f == null) return;
  instPage.importBundle(f.getAbsolutePath());
}
