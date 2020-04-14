// Instrument class. Holds data about instruments
// Voice class. Plays a single note.

class Instrument {
    
  ArrayList<Voice> voices;
  String name;
  
  int waveform;
  float volume = 0.5;
  float lowpass = 1;
  float hue = 50;
  float decayTime = 0.5;
  float noisePitch = 0.5;
  
  boolean loopEnvelope;
  
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
  
  void playNote(Note n) {
    if(n.playing) return;
    Voice v = new Voice(this, n);
    n.playing = true;
    voices.add(v);
  }
  
  void update() {
    for(int i = voices.size() - 1; i >= 0; i --) {
      Voice v = voices.get(i);
      v.update();
      if(v.timer < 0) {
        v.delete();
        voices.remove(i);
      }
    }
  }
  
  void displayIcon(float w, float h, boolean selected) {
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
  
  void displayEditor(float w, float h) {
    fill(app.inspectorColor);
    rect(0, 0, sliderPanelWidth, h);
    
    waveform = round((waveformNames.length - 1) * slider(0, "Waveform " + waveformNames[waveform], (float)waveform / (waveformNames.length - 1)));
    volume = slider(1, "Volume " + str(floor(volume * 100)) + "%", volume);
    if(waveform != 4) {
      String lowpassMsg = "Low Pass";
      if(lowpass > 0.95) lowpassMsg += " OFF";
      else lowpassMsg += " " + str(floor(getLowPassFreq()));
      lowpass = slider(2, lowpassMsg, lowpass);
    }
    decayTime = slider(3, "Decay Speed " + str((float)floor(2000 * decayTime) / 100), decayTime);
    hue = map(slider(5, "Color", map(hue, 0, 360, 0, 1)), 0, 1, 0, 360);
    if(waveform == 4) {
      noisePitch = slider(2, "Noise Pitch " + str((float)floor(noisePitch * 100) / 100), noisePitch);
    }
    
    String msg = "Loop Envelope " + (loopEnvelope ? "Yes" : "No");
    loopEnvelope = slider(4, msg, (loopEnvelope ? 1 : 0)) > 0.5;
    
    // Envelope
    
    pushMatrix();
    translate(sliderPanelWidth,  h / 2);
    stroke(app.accentColor);
    noFill();
    beginShape();
    for(int i = 0; i < points; i ++) {
      vertex(map(i, 0, points, 0, w - sliderPanelWidth), map(envelope[i], 0, 1, h / 3, -h / 3));
    }
    if(!loopEnvelope) {
      vertex(w - sliderPanelWidth, h / 3);
    } else {
      vertex(w - sliderPanelWidth, map(envelope[0], 0, 1, h / 3, -h / 3));
    }
    endShape();
    
    noStroke();
    fill(app.accentColor);
    for(int i = 0; i < points; i ++) {
      rect(map(i, 0, points, 0, w - sliderPanelWidth) - 5, map(envelope[i], 0, 1, h / 3, -h / 3) - 5, 10, 10);
    }
    popMatrix();
  }
  
  float slider(int y, String name, float val) {
    pushMatrix();
    translate(0, y * 45 + 16);
    
    textSize(16);
    fill(app.textColor);
    text(name, (sliderPanelWidth - textWidth(name)) / 2, 5);
    
    fill(app.navBarColor);
    rect(0, 16, sliderPanelWidth, 15);
    
    fill(app.accentColor);
    float knobX = map(val, 0, 1, 7.5, sliderPanelWidth - 7.5);
    rect(knobX - 7.5, 16, 15, 15);
    
    popMatrix();
    
    if(mousePressed && mouseX < sliderPanelWidth) {
      float my = mouseY - app.navigationBarHeight;
      if(my > y * 45 + 32 && my < y * 45 + 48) {
        return constrain(map(mouseX, 7.5, sliderPanelWidth - 7.5, 0, 1), 0, 1);
      }
    }
    
    return val;
  }
  
  float getVol(float t) {
    float time = t * decayTime * 20;
    int envPoint = floor(time);
    if(loopEnvelope) envPoint %= envelope.length;
    float amp = 0;
    if(envPoint < points) {
      float left = envelope[envPoint];
      float right = 0;
      if(loopEnvelope) right = envelope[0];
      if(envPoint < points - 1) right = envelope[envPoint + 1];
      amp = right * (time % 1) + left * (1 - time % 1);
    }
    return volume * amp;
  }
  
  void drag(float x, float y, float w, float h) {
    for(int i = 0; i < points; i ++) {
      float px = map(i, 0, points, sliderPanelWidth, w);
      float py = map(envelope[i], 0, 1, h / 3 + h / 2, -h / 3 + h / 2);
      
      float dist = dist(x, pmouseY - app.navigationBarHeight, px, py);
      if(dist < 10) {
        envelope[i] = constrain(map(y - h / 2, -h / 3, h / 3, 1, 0), 0, 1);
      }
    }
  }
  
  float getLowPassFreq() {
    return map(lowpass, 0, 1, 200, 2000);
  }
  
  color getColor() {
    colorMode(HSB);
    color c = color(map(hue, 0, 360, 0, 255), 125, 255);
    colorMode(RGB);
    return c;
  }
  
  String toString() {
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
    result += str(noisePitch) + ",";
    result += (loopEnvelope ? 1 : 0);
    return result;
  }
  
  void load(String data) {
    String[] parts = data.split(",");
    name = parts[0];
    for(int i = 0; i < envelope.length; i ++) {
      envelope[i] = float(parts[i + 1]);
    }
    waveform = int(parts[envelope.length + 1]);
    volume = float(parts[envelope.length + 2]);
    lowpass = float(parts[envelope.length + 3]);
    hue = float(parts[envelope.length + 4]);
    decayTime = float(parts[envelope.length + 5]);
    noisePitch = float(parts[envelope.length + 6]);
    loopEnvelope = float(parts[envelope.length + 7]) > 0.5;
  }
  
  void stopAll() {
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
      if(inst.lowpass > 0.95) {
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
    timer = midiPage.beatLength * (n.endTime - n.startTime);
    maxTime = timer;
  }
  
  void update() {
    timer -= delta;
    if(!useNoise) {
      if(inst.waveform != 4) osc.setWaveform(waves[inst.waveform]);
      osc.setAmplitude(inst.getVol(maxTime - timer));
    } else {
      mult.setValue(inst.getVol(maxTime - timer));
    }
    if(n.deleted) timer = -100;
  }
  
  void delete() {
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
