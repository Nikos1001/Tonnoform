import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import ddf.minim.*; 
import ddf.minim.analysis.*; 
import ddf.minim.effects.*; 
import ddf.minim.signals.*; 
import ddf.minim.spi.*; 
import ddf.minim.ugens.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class Tonnoform extends PApplet {

// Main File








Minim minim;
AudioOutput audioOut;
App app;

ProjectPage projPage;
InstrumentPage instPage;
Sequencer sequencer;

float ptime = 0;
float delta;

public void setup() {
  textSize(18);
  
  
  surface.setTitle("Tonnoform");
  surface.setResizable(true);
  minim = new Minim(this);
  audioOut = minim.getLineOut();
  app = new App();
}

public void draw() {
  delta = (millis() - ptime) / 1000;
  ptime = millis();
  app.display();
}

public void keyPressed() {
  if(key == ESC) key = 0;
  app.keyDown();
}

public void mousePressed() {
  app.click();
}

public void mouseDragged() {
  app.drag();
}
// App class. Contains all UI Pages

class App {
  
  public final float navigationBarHeight = 40;
  public final float tabNameMargin = 20;
  public final float tabNameYMargin = 25;
  public final float inspectorDragBar = 15;
  
  public float inspectorWidth = width / 3;
  
  public final int bgColor = color(60);
  public final int darkBarColor = color(25);
  public final int navBarColor = color(32.5f);
  public final int darkInspectorColor = color(35);
  public final int inspectorColor = color(40);
  public final int bgDarkerColor = color(52.5f);
  public final int textColor = color(255);
  public final int accentColor = color(255, 232, 137);
  
  boolean disableControlls = false;
  
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
  
  public void display() {
    
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
  
  public void keyDown() {
    if(disableControlls) return;
    pages[selectedPage].keyDown();
  }
  
  public void click() {
    if(disableControlls) return;
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
  
  public void drag() {
    if(disableControlls) return;
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
  
  public void save(String path) {
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
  
  public void load(String path) {
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
// Instrument class. Holds data about instruments
// Voice class. Plays a single note.

class Instrument {
    
  ArrayList<Voice> voices;
  String name;
  
  int waveform;
  float volume = 0.5f;
  float lowpass = 1;
  float hue = 50;
  float decayTime = 0.5f;
  float noisePitch = 0.5f;
  
  public final String[] waveformNames = {"SQR", "SIN", "TRI", "SAW", "NOISE"};
  public final int points = 10;
  
  public final float sliderPanelWidth = 200;
  
  float[] envelope;
  
  Instrument(String name) {
    voices = new ArrayList<Voice>();
    this.name = name;
    envelope = new float[points];
    for(int i = 0; i < points; i ++) {
      envelope[i] = 1 - (float)i / points;
    }
  }
  
  public void playNote(Note n) {
    if(n.playing) return;
    Voice v = new Voice(this, n);
    n.playing = true;
    voices.add(v);
  }
  
  public void update() {
    for(int i = voices.size() - 1; i >= 0; i --) {
      Voice v = voices.get(i);
      v.update();
      if(v.timer < 0) {
        v.delete();
        voices.remove(i);
      }
    }
  }
  
  public void displayIcon(float w, float h, boolean selected) {
    if(selected) {
      fill(app.accentColor);
      rect(0, 0, 5, h);
    }
    fill(app.textColor);
    String msg = name;
    float scl = 2 * h / 3;
    while(textWidth(msg) > 3 * w / 3) {
      scl -= 1;
      textSize(scl);
    }
    colorMode(HSB);
    fill(map(hue, 0, 360, 0, 255), 125, 255);
    rect(w - h, 0, h, h);
    colorMode(RGB);
    
    fill(app.textColor);
    text(msg, (w - textWidth(msg)) / 2, (h + textAscent() - textDescent()) / 2);
  }
  
  public void displayEditor(float w, float h) {
    fill(app.inspectorColor);
    rect(0, 0, sliderPanelWidth, h);
    
    waveform = round((waveformNames.length - 1) * slider(0, "Waveform " + waveformNames[waveform], (float)waveform / (waveformNames.length - 1)));
    volume = slider(1, "Volume " + str(floor(volume * 100)) + "%", volume);
    if(waveform != 4) {
      String lowpassMsg = "Low Pass";
      if(lowpass > 0.95f) lowpassMsg += " OFF";
      else lowpassMsg += " " + str(floor(getLowPassFreq()));
      lowpass = slider(2, lowpassMsg, lowpass);
    }
    decayTime = slider(3, "Decay Speed " + str((float)floor(2000 * decayTime) / 100), decayTime);
    hue = map(slider(4, "Color", map(hue, 0, 360, 0, 1)), 0, 1, 0, 360);
    if(waveform == 4) {
      noisePitch = slider(2, "Noise Pitch " + str((float)floor(noisePitch * 100) / 100), noisePitch);
    }
    
    // Envelope
    
    pushMatrix();
    translate(sliderPanelWidth,  h / 2);
    stroke(app.accentColor);
    noFill();
    beginShape();
    for(int i = 0; i < points; i ++) {
      vertex(map(i, 0, points, 0, w - sliderPanelWidth), map(envelope[i], 0, 1, h / 3, -h / 3));
    }
    vertex(w - sliderPanelWidth, h / 3);
    endShape();
    
    noStroke();
    fill(app.accentColor);
    for(int i = 0; i < points; i ++) {
      rect(map(i, 0, points, 0, w - sliderPanelWidth) - 5, map(envelope[i], 0, 1, h / 3, -h / 3) - 5, 10, 10);
    }
    popMatrix();
  }
  
  public float slider(int y, String name, float val) {
    pushMatrix();
    translate(0, y * 45 + 16);
    
    textSize(16);
    fill(app.textColor);
    text(name, (sliderPanelWidth - textWidth(name)) / 2, 5);
    
    fill(app.navBarColor);
    rect(0, 16, sliderPanelWidth, 15);
    
    fill(app.accentColor);
    float knobX = map(val, 0, 1, 7.5f, sliderPanelWidth - 7.5f);
    rect(knobX - 7.5f, 16, 15, 15);
    
    popMatrix();
    
    if(mousePressed && mouseX < sliderPanelWidth) {
      float my = mouseY - app.navigationBarHeight;
      if(my > y * 45 + 32 && my < y * 45 + 48) {
        return constrain(map(mouseX, 7.5f, sliderPanelWidth - 7.5f, 0, 1), 0, 1);
      }
    }
    
    return val;
  }
  
  public float getVol(float t) {
    float time = t * decayTime * 20;
    int envPoint = floor(time);
    float amp = 0;
    if(envPoint < points) {
      float left = envelope[envPoint];
      float right = 0;
      if(envPoint < points - 1) right = envelope[envPoint + 1];
      amp = right * (time % 1) + left * (1 - time % 1);
    }
    return volume * amp;
  }
  
  public void drag(float x, float y, float w, float h) {
    for(int i = 0; i < points; i ++) {
      float px = map(i, 0, points, sliderPanelWidth, w);
      float py = map(envelope[i], 0, 1, h / 3 + h / 2, -h / 3 + h / 2);
      
      float dist = dist(x, pmouseY - app.navigationBarHeight, px, py);
      if(dist < 10) {
        envelope[i] = constrain(map(y - h / 2, -h / 3, h / 3, 1, 0), 0, 1);
      }
    }
  }
  
  public float getLowPassFreq() {
    return map(lowpass, 0, 1, 200, 2000);
  }
  
  public int getColor() {
    colorMode(HSB);
    int c = color(map(hue, 0, 360, 0, 255), 125, 255);
    colorMode(RGB);
    return c;
  }
  
  public String toString() {
    String result = name;
    result += ",";
    for(int i = 0; i < envelope.length; i ++) {
      result += str(envelope[i]) + ",";
    }
    result += str(waveform) + ",";
    result += str(volume) + ",";
    result += str(lowpass) + ",";
    result += str(hue) + ",";
    result += str(decayTime) + ",";
    result += str(noisePitch);
    return result;
  }
  
  public void load(String data) {
    String[] parts = data.split(",");
    name = parts[0];
    for(int i = 0; i < envelope.length; i ++) {
      envelope[i] = PApplet.parseFloat(parts[i + 1]);
    }
    waveform = PApplet.parseInt(parts[envelope.length + 1]);
    volume = PApplet.parseFloat(parts[envelope.length + 2]);
    lowpass = PApplet.parseFloat(parts[envelope.length + 3]);
    hue = PApplet.parseFloat(parts[envelope.length + 4]);
    decayTime = PApplet.parseFloat(parts[envelope.length + 5]);
    noisePitch = PApplet.parseFloat(parts[envelope.length + 6]);
  }
  
  public void stopAll() {
    for(Voice v : voices) {
      v.delete();
    }
    voices = new ArrayList<Voice>();
  }
  
}



class Voice {
  
  Oscil osc;
  LowPassFS lpf;
  Instrument inst;
  float timer;
  float maxTime;
  Note n;
  
  Noise noise;
  Multiplier mult;
  BitCrush bitCrush;
  boolean useNoise;
  
  float lpfFreq;
  boolean useLpf;
  
  public final Waveform[] waves = {Waves.SQUARE, Waves.SINE, Waves.TRIANGLE, Waves.SAW, null};
  
  Voice(Instrument inst, Note n) {
    this.n = n;
    this.inst = inst;
    if(inst.waveform != 4) {
      osc = new Oscil(440 * pow(2, (float)n.note / 12), 1, waves[inst.waveform]);
      lpfFreq = inst.getLowPassFreq();
      lpf = new LowPassFS(lpfFreq, audioOut.sampleRate());
      if(inst.lowpass > 0.95f) {
        osc.patch(audioOut);
      } else {
        osc.patch(lpf).patch(audioOut);
        useLpf = true;
      }
      osc.setAmplitude(inst.getVol(0));
    } else {
      useNoise = true;
      noise = new Noise();
      mult = new Multiplier();
      bitCrush = new BitCrush(1, audioOut.sampleRate() * inst.noisePitch);
      noise.patch(bitCrush).patch(mult).patch(audioOut);
      mult.setValue(inst.getVol(0));
    }
    timer = MIDIPage.beatLength * (n.endTime - n.startTime);
    maxTime = timer;
  }
  
  public void update() {
    timer -= delta;
    if(!useNoise) {
      if(inst.waveform != 4) osc.setWaveform(waves[inst.waveform]);
      osc.setAmplitude(inst.getVol(maxTime - timer));
    } else {
      mult.setValue(inst.getVol(maxTime - timer));
    }
    if(n.deleted) timer = -100;
  }
  
  public void delete() {
    n.playing = false;
    if(!useNoise) {
      if(!useLpf) {
        osc.unpatch(audioOut);
      } else {
        lpf.unpatch(audioOut);
      }
    } else {
      noise.unpatch(bitCrush);
      bitCrush.unpatch(mult);
      mult.unpatch(audioOut);
    }
  }
  
}
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
  
  public void displayMain(float w, float h) {
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
  
  public void displayInspector(float w, float h) {
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
  
  public void inspectorClick(float x, float y, float w, float h) {
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
  
  public void update() {
    for(Instrument inst : instruments) {
      inst.update();
    }
  }
  
  public void plus() {
    instrumentID ++;
    instruments.add(new Instrument("Instrument" + str(instrumentID)));
    scroll ++;
  }
  
  public void minus() {
    if(instruments.size() == 1) return;
    Instrument i = instruments.get(selectedInstrument);
    instruments.remove(selectedInstrument);
    selectedInstrument --;
    if(selectedInstrument < 0) selectedInstrument = 0;
  }
  
  public void keyDown() {
    if(key == 's') scroll ++;
    if(key == 'w') scroll --;
  }
  
  public void drag(float x, float y, float w, float h) {
    if(instruments.size() > 0) {
      instruments.get(selectedInstrument).drag(x, y, w, h);
    }
  }
  
  public ArrayList<String> getData() {
    ArrayList<String> result = new ArrayList<String>();
    result.add(str(instrumentID));
    for(Instrument inst : instruments) result.add(inst.toString());
    return result;
  }
  
  public void load(ArrayList<String> data) {
    instrumentID = PApplet.parseInt(data.get(0));
    instruments = new ArrayList<Instrument>();
    for(int i = 1; i < data.size(); i ++) {
      Instrument inst = new Instrument("");
      inst.load(data.get(i));
      instruments.add(inst);
    }
  }
  
  public void exportBundle(String path) {
    String[] data = new String[instruments.size()];
    for(int i = 0; i < instruments.size(); i ++) {
      data[i] = instruments.get(i).toString();
    }
    saveStrings(dataPath(path + ".tnfinsts"), data);
  }
  
  public void importBundle(String path) {
    String[] data = loadStrings(dataPath(path));
    instruments = new ArrayList<Instrument>();
    for(int i = 0; i < data.length; i ++) {
      Instrument inst = new Instrument("");
      inst.load(data[i]);
      instruments.add(inst);
    }
  }
  
}
// MIDI UI

class MIDIPage extends UIPage {
  
  public final float inspectorToolbarHeight = 40;
  public float sequencerHeight = 0;
  
  public final static int bars = 4, npb = 4;
  
  public final int maxPatterns = 15;
  
  public static final float beatLength = 0.25f;
  
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

  public void displayInspector(float w, float h) {
    
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
  
  public void inspectorClick(float x, float y, float w, float h) {
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
  
  public void displayMain(float w, float h) {
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
  
  public void mainClick(float x, float y, float w, float h) {
    if(y < h - sequencerHeight) {
      if(patterns.size() > 0) {
        patterns.get(selectedPattern).click(x, y, w, h - sequencerHeight);
      }
    } else {
      seq.click(x, y - (h - sequencerHeight), w, sequencerHeight);
    }
  }
  
  public void drag(float x, float y, float w, float h) {
    if(y < h - sequencerHeight) {
      patterns.get(selectedPattern).drag(x, y, w, h - sequencerHeight);
    }
  }
  
  public void plus() {
    patternID ++;
    patterns.add(new Pattern("Pattern" + str(patternID)));
    scroll ++;
  }
  
  public void minus() {
    if(patterns.size() == 0) return;
    Pattern p = patterns.get(selectedPattern);
    patterns.remove(selectedPattern);
    selectedPattern --;
    if(selectedPattern < 0) selectedPattern = 0;
    seq.removePattern(p);
  }
  
  public void keyDown() {
    if(patterns.size() > 0) {
      patterns.get(selectedPattern).keyDown();
    }
    if(key == ' ') seq.togglePause();
    if(key == 's') scroll ++;
    if(key == 'w') scroll --;
    seq.keyDown();
  }

  public void update() {
    for(int i = 0; i < patterns.size(); i ++) {
      patterns.get(i).index = i;
    }
    seq.update();
  }
  
  public ArrayList<String> getData() {
    ArrayList<String> data = new ArrayList<String>();
    data.add(str(patternID));
    for(Pattern p : patterns) {
      data.add(p.toString());
    }
    data.add("==");
    for(String line : seq.getData()) {
      data.add(line);
    }
    return data;
  }
  
  public void load(ArrayList<String> data) {
    ArrayList<String> mainDat = new ArrayList<String>(), seqDat = new ArrayList<String>();
    boolean main = true;
    for(int i = 0; i < data.size(); i ++) {
      if(data.get(i).equals("==")) {
        main = false;
      } else {
        if(main) mainDat.add(data.get(i));
        else seqDat.add(data.get(i));
      }
    }
    
    // Main data
    patternID = PApplet.parseInt(mainDat.get(0));
    patterns = new ArrayList<Pattern>();
    for(int i = 1; i < mainDat.size(); i ++) {
      Pattern p = new Pattern("");
      p.load(mainDat.get(i));
      patterns.add(p);
    }
    
    seq.load(seqDat);
  }

}

class Pattern {
  
  public final String[] noteNames = {"A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#"};
  
  String name;
  ArrayList<Note> notes;
  Note currentNote;
  int pivotTime;
  int id;
  
  int index;
  
  int panY = 0;
  
  int bars = MIDIPage.bars, npb = MIDIPage.npb;
  int shownNotes = 17;
  
  Pattern(String name) {
    this.name = name;
    notes = new ArrayList<Note>();
  }
  
  public void displayIcon(float w, float h, boolean selected, int c) {
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
  
  public void displayEditor(float w, float h) {
    
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
        rect(x + 2.5f, y + 2.5f, noteWidth * (n.endTime - n.startTime) - 5, noteHeight - 5);
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
  
  public void click(float x, float y, float w, float h) {
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
  
  public void drag(float x, float y, float w, float h) {
    int patternNotes = bars * npb;
    float noteWidth = w / patternNotes;
    float noteHeight = h / shownNotes;
    int nx = floor(x / noteWidth);
    int ny = -floor(y / noteHeight) - panY;
    
    if(currentNote != null) {
      if(nx >= pivotTime) {
        currentNote.endTime = nx + 1;
      } else {
        currentNote.startTime = nx;
      }
    }
  }
  
  public void keyDown() {
    if(keyCode == UP) panY --;
    if(keyCode == DOWN) panY ++;
  }
  
  public ArrayList<Note> getNotesAt(int t) {
    ArrayList<Note> result = new ArrayList<Note>();
    for(Note n : notes) {
      if(n.startTime <= t && n.endTime > t) result.add(n);
    }
    return result;
  }
  
  public String toString() {
    String result = name + "/";
    for(Note n : notes) result += n.toString() + "/";
    return result;
  }
  
  public void load(String str) {
    String[] parts = str.split("/");
    for(String part : parts) println(part);
    name = parts[0];
    for(int i = 1; i < parts.length; i ++) {
      String[] values = parts[i].split(",");
      Note n = new Note(PApplet.parseInt(values[0]), PApplet.parseInt(values[1]), PApplet.parseInt(values[2]));
      notes.add(n);
    }
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
  
  public String toString() {
    return str(startTime) + "," +  str(endTime) + "," + str(note);
  }
  
}


class ProjectPage extends UIPage {
  
  ProjectPage() {
    super();
    name = "Project";
  }
  
  public void displayInspector(float w, float h) {
    fill(app.textColor);
    textSize(16);
    text("Save Project", 10, 20);
    text("Load Project", 10, 40);
    text("Export WAV", 10, 60);
    text("Export Instrument Bundle", 10, 80);
    text("Import Instrument Bundle", 10, 100);
  }
  
  public void inspectorClick(float x, float y, float w, float h) {
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


public void saveDialog(File f) {
  if(f != null) app.save(f.getAbsolutePath());
}

public void openDialog(File f) {
  if(f == null) return;
  app.load(f.getAbsolutePath());
}

public void exportDialog(File f) {
  if(f == null) return;
  sequencer.export(f.getAbsolutePath());
}

public void exportInstDialog(File f) {
  if(f == null) return;
  instPage.exportBundle(f.getAbsolutePath());
}

public void importInstDialog(File f) {
  if(f == null) return;
  instPage.importBundle(f.getAbsolutePath());
}
// Sequencer UI

class Sequencer {
  
  MIDIPage midi;
  ArrayList<SequencePattern> patterns;
  
  AudioRecorder recorder;
  boolean recording;
  
  public final int horizPatterns = 10;
  public final int vertPatterns = 5;
  
  int selectedInst;
  int scrollX;
  
  float time;
  
  boolean isPaused = false;
  
  Sequencer(MIDIPage midi) {
    this.midi = midi;
    patterns = new ArrayList<SequencePattern>();
    sequencer = this;
  }
  
  public void displayEditor(float w, float h) {
    
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
      rect(x * iconWidth - 1.5f, 0, 3, h - midi.inspectorToolbarHeight);
    }
    
    for(SequencePattern p : patterns) {
      if(p.time >= scrollX && p.time < scrollX + horizPatterns) {
        float x = map(p.time - scrollX, 0, horizPatterns, 0, w);
        float y = map(p.y, 0, vertPatterns, 0, h - midi.inspectorToolbarHeight);
        pushMatrix();
        translate(x, y);
        p.p.displayIcon(iconWidth, iconHeight, false, p.getColor());
        popMatrix();
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
  
  public void click(float x, float y, float w, float h) {
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
  
  public void removePattern(Pattern p) {
    for(int i = patterns.size() - 1; i >= 0; i --) {
      if(patterns.get(i).p.name.equals(p.name)) {
        patterns.remove(i);
      }
    }
  }
  
  public void update() {
    
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
    } else {
      //for(Instrument inst : instPage.instruments) {
      //  inst.stopAll();
      //}
    }
    for(int i = patterns.size() - 1; i >= 0; i --) {
      if(patterns.get(i).shouldRemove()) patterns.remove(i);
    }
    
  }
  
  public void togglePause() {
   this.isPaused = !this.isPaused; 
  }
  
  public ArrayList<String> getData() {
    ArrayList<String> result = new ArrayList<String>();
    for(SequencePattern p : patterns) result.add(p.toString());
    return result;
  }
  
  public void load(ArrayList<String> data) {
    patterns = new ArrayList<SequencePattern>();
    for(String line : data) {
      SequencePattern pattern = new SequencePattern(line, midi);
      patterns.add(pattern);
    }
  }
  
  public void export(String path) {
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
  
  public void keyDown() {
    if(keyCode == RIGHT) scrollX ++;
    if(keyCode == LEFT) scrollX = max(0, scrollX - 1);
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
    p = midi.patterns.get(PApplet.parseInt(parts[0]));
    instID = PApplet.parseInt(parts[1]);
    instName = parts[2];
    time = PApplet.parseInt(parts[3]);
    y = PApplet.parseInt(parts[4]);
  }
  
  SequencePattern(Pattern p, int t, int y, int instID) {
    this.p = p;
    time = t;
    this.y = y;
    this.instID = instID;
    instName = instPage.instruments.get(instID).name;
  }
  
  public boolean shouldRemove() {
    return !instPage.instruments.get(instID).name.equals(instName);
  }
  
  public int getColor() {
    colorMode(HSB);
    int c = color(map(getInst().hue, 0, 360, 0, 255), 125, 255);
    colorMode(RGB);
    return c;
  }
  
  public Instrument getInst() {
    return instPage.instruments.get(instID);
  }
  
  public String toString() {
    return str(p.index) + "," + str(instID) + "," + instName + "," + str(time) + "," + str(y);
  }
  
}
// UI Page

abstract class UIPage {
  
  public String name;

  UIPage() {
    name = "UI Page";
  }
  
  public void displayInspector(float w, float h) {
    
  }
  
  public void inspectorClick(float x, float y, float w, float h) {

  }
  
  public void displayMain(float w, float h) {
    
  }
  
  public void mainClick(float x, float y, float w, float h) {
    
  }
  
  public void drag(float x, float y, float w, float h) {
    
  }
  
  public void keyDown() {
    
  }
  
  public void update() {
    
  }
  
  public ArrayList<String> getData() {
    ArrayList<String> data = new ArrayList<String>();
    return data;
  }
  
  public void load(ArrayList<String> data) {
  
  }
  
}
  public void settings() {  size(1000, 600);  noSmooth(); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "Tonnoform" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
