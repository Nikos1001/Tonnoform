

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
  }
  
  void inspectorClick(float x, float y, float w, float h) {
    if(y < 20) {
      selectOutput("Choose location to save", "saveDialog");
    }
    if(y > 20 && y < 40) {
      selectInput("Choose file to open", "openDialog");
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
