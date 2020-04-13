// Instrument UI

class InstrumentPage extends UIPage {
    
  ArrayList<Instrument> instruments;
  public final float inspectorToolbarHeight = 40;
  int scroll;
  int maxInstruments = 15;
  int selectedInstrument;
  
  int instrumentID;
  
  InstrumentPage() {
    super();
    name = "Instrument";
    instruments = new ArrayList<Instrument>();
    instruments.add(new Instrument("Default Instrument"));
  }
  
  void displayMain(float w, float h) {
    if(instruments.size() == 0) {
      String msg = "Click the + to create a new instrument";
      textSize(18);
      float txtX = (w - textWidth(msg)) / 2;
      float txtY = (h - textAscent() - textDescent()) / 2;
      fill(app.textColor);
      text(msg, txtX, h / 2);
    } else {
      instruments.get(selectedInstrument).displayEditor(w, h);
    }
  }
  
  void displayInspector(float w, float h) {
    if(scroll > instruments.size() - maxInstruments) scroll = instruments.size() - maxInstruments;
    if(scroll < 0) scroll = 0; 
    
    fill(app.navBarColor);
    rect(0, h - inspectorToolbarHeight, w, inspectorToolbarHeight);
    
    fill(app.textColor);
    textSize(28);
    float txtX = w - inspectorToolbarHeight / 2 - textWidth("+") / 2;
    float txtY = h - (textAscent() + textDescent()) / 2 + 2;
    text("-", txtX, txtY);
    text("+", txtX - inspectorToolbarHeight, txtY);
    
    if(instruments.size() > 0) {
      textSize(16);
      txtY = h - inspectorToolbarHeight / 2 + 8;
      text("TEST", inspectorToolbarHeight / 2, txtY);
    }
    
    float instrumentHeight = (h - inspectorToolbarHeight) / maxInstruments;
    if(instruments.size() < maxInstruments) {
      for(int i = 0; i < instruments.size(); i ++) {
        pushMatrix();
        translate(0, i * instrumentHeight);
        instruments.get(i).displayIcon(w, instrumentHeight, i == selectedInstrument);
        popMatrix();
      }
    } else {
      for(int i = scroll; i < scroll + maxInstruments; i ++) {
        pushMatrix();
        translate(0, (i - scroll) * instrumentHeight);
        instruments.get(i).displayIcon(w, instrumentHeight, i == selectedInstrument);
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
      textSize(16);
      if(x < inspectorToolbarHeight + textWidth("TEST") && instruments.size() > 0) {
        instruments.get(selectedInstrument).playNote(new Note(0, 10, 0));
      }
    } else {
      float VoiceHeight = (h - inspectorToolbarHeight) / maxInstruments;
      if(instruments.size() < maxInstruments) {
        selectedInstrument = min(floor(y / VoiceHeight), instruments.size() - 1);
      } else {
        selectedInstrument = floor(y / VoiceHeight) - scroll;
      }
    }
  }
  
  void update() {
    for(Instrument inst : instruments) {
      inst.update();
    }
  }
  
  void plus() {
    instrumentID ++;
    instruments.add(new Instrument("Instrument" + str(instrumentID)));
    scroll ++;
  }
  
  void minus() {
    if(instruments.size() == 1) return;
    Instrument i = instruments.get(selectedInstrument);
    instruments.remove(selectedInstrument);
    selectedInstrument --;
    if(selectedInstrument < 0) selectedInstrument = 0;
  }
  
  void keyDown() {
    if(key == 's') scroll ++;
    if(key == 'w') scroll --;
  }
  
  void drag(float x, float y, float w, float h) {
    if(instruments.size() > 0) {
      instruments.get(selectedInstrument).drag(x, y, w, h);
    }
  }
  
  ArrayList<String> getData() {
    ArrayList<String> result = new ArrayList<String>();
    result.add(str(instrumentID));
    for(Instrument inst : instruments) result.add(inst.toString());
    return result;
  }
  
  void load(ArrayList<String> data) {
    instrumentID = int(data.get(0));
    instruments = new ArrayList<Instrument>();
    for(int i = 1; i < data.size(); i ++) {
      Instrument inst = new Instrument("");
      inst.load(data.get(i));
      instruments.add(inst);
    }
  }
  
  void exportBundle(String path) {
    String[] data = new String[instruments.size()];
    for(int i = 0; i < instruments.size(); i ++) {
      data[i] = instruments.get(i).toString();
    }
    saveStrings(dataPath(path + ".tnfinsts"), data);
  }
  
  void importBundle(String path) {
    String[] data = loadStrings(dataPath(path));
    instruments = new ArrayList<Instrument>();
    for(int i = 0; i < data.length; i ++) {
      Instrument inst = new Instrument("");
      inst.load(data[i]);
      instruments.add(inst);
    }
  }
  
}
