// App class. Contains all UI Pages

class App {
  
  public final float navigationBarHeight = 40;
  public final float tabNameMargin = 20;
  public final float tabNameYMargin = 25;
  public final float inspectorDragBar = 15;
  
  public float inspectorWidth = width / 3;
  
  public final color bgColor = color(60);
  public final color darkBarColor = color(25);
  public final color navBarColor = color(32.5);
  public final color darkInspectorColor = color(35);
  public final color inspectorColor = color(40);
  public final color bgDarkerColor = color(52.5);
  public final color textColor = color(255);
  public final color accentColor = color(255, 232, 137);
  
  UIPage[] pages;
  int selectedPage;
  
  App() {
    
    PFont font = createFont("assets/font2.ttf", 12);
    textFont(font);
    
    pages = new UIPage[3];
    projPage = new ProjectPage();
    pages[0] = projPage;
    pages[1] = new MIDIPage();
    instPage = new InstrumentPage();
    pages[2] = instPage;
  }
  
  void display() {
    
    for(UIPage page : pages) {
      page.update();
    }
    
    noStroke();
    background(bgColor);
    
    // Navigation Panel
    fill(navBarColor);
    rect(0, 0, width, navigationBarHeight);
    pushMatrix();
    for(int i = 0; i < pages.length; i ++) {
      UIPage page = pages[i];
      textSize(navigationBarHeight - tabNameYMargin);
      float tabWidth = textWidth(page.name) + tabNameMargin;
      if(i == selectedPage) {
        fill(bgColor);
        rect(0, 0, tabWidth, navigationBarHeight);
      }
      fill(textColor);
      text(page.name, tabNameMargin / 2, navigationBarHeight - tabNameYMargin / 2);
      translate(tabWidth, 0);
    }
    popMatrix();
    
    pushMatrix();
    translate(0, navigationBarHeight);
    
    // Inspector
    pushMatrix();
    translate(width - inspectorWidth, 0);
    fill(inspectorColor);
    rect(0, 0, inspectorWidth, height - navigationBarHeight);
    pages[selectedPage].displayInspector(inspectorWidth, height - navigationBarHeight);
    if(mouseX > width - inspectorWidth && mouseX < width - inspectorWidth + inspectorDragBar) {
      fill(darkBarColor);
      float h = height - navigationBarHeight;
      float w = inspectorDragBar;
      rect(w / 3, h / 3, w / 3, h / 3, h / 3);
    }
    popMatrix();
    
    // Main Body
    pages[selectedPage].displayMain(width - inspectorWidth, height - navigationBarHeight);
    
    popMatrix();
    
  }
  
  void keyDown() {
    pages[selectedPage].keyDown();
  }
  
  void click() {
    if(mouseY < navigationBarHeight) {
      float currentX = 0;
      for(int i = 0; i < pages.length; i ++) {
        UIPage page = pages[i];
        float tabWidth = textWidth(page.name) + tabNameMargin;
        if(mouseX > currentX && mouseX < currentX + tabWidth) {
          selectedPage = i;
          return;
        }
        currentX += tabWidth;
      }
    } else {
      if(mouseX > width - inspectorWidth + inspectorDragBar) {
        pages[selectedPage].inspectorClick(mouseX - width + inspectorWidth, mouseY - navigationBarHeight, inspectorWidth, height - navigationBarHeight);
      }
      if(mouseX < width - inspectorWidth) {
        pages[selectedPage].mainClick(mouseX, mouseY - navigationBarHeight, width - inspectorWidth, height - navigationBarHeight);
      }
    }
  }
  
  void drag() {
    if(mouseY > navigationBarHeight) {
      if(pmouseX > width - inspectorWidth && pmouseX < width - inspectorWidth + inspectorDragBar) {
        inspectorWidth = width - mouseX + inspectorDragBar / 2;
        inspectorWidth = min(width / 3, inspectorWidth);
        inspectorWidth = max(width / 6, inspectorWidth);
      }
      if(mouseX < width - inspectorWidth) {
        pages[selectedPage].drag(mouseX, mouseY - navigationBarHeight, width - inspectorWidth, height - navigationBarHeight);
      }
    }
  }
  
  void save(String path) {
    println(path);
    ArrayList<String> data = new ArrayList<String>();
    for(int i = 0; i < pages.length; i ++) {
      ArrayList<String> pageData = pages[i].getData();
      for(String line : pageData) data.add(line);
      data.add("===");
    }
    String[] fileDat = new String[data.size()];
    for(int i = 0; i < fileDat.length; i ++) {
      fileDat[i] = data.get(i);
    }
    saveStrings(dataPath(path + ".tnfproj"), fileDat);
  }
  
  void load(String path) {
    println(path);
    String[] data = loadStrings(dataPath(path));
    int index = 0;
    for(int i = 0; i < pages.length; i ++) {
      ArrayList<String> pageData = new ArrayList<String>();
      while(!data[index].equals("===")) {
        pageData.add(data[index]);
        index ++;
      }
      index ++;
      
      pages[i].load(pageData);
    }
  }
  
}
