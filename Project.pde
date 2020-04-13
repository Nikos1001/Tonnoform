

class ProjectPage extends UIPage {
  
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
  }
  
}


void saveDialog(File f) {
  if(f != null) app.save(f.getAbsolutePath());
}

void openDialog(File f) {
  if(f == null) return;
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
