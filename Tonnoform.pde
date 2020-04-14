// Main File

import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput audioOut;
App app;

ProjectPage projPage;
InstrumentPage instPage;
Sequencer sequencer;
MIDIPage midiPage;

float ptime = 0;
float delta;

void setup() {
  textSize(18);
  noSmooth();
  size(1000, 600);
  surface.setTitle("Tonnoform");
  surface.setResizable(true);
  minim = new Minim(this);
  audioOut = minim.getLineOut();
  app = new App();
}

void draw() {
  delta = (millis() - ptime) / 1000;
  ptime = millis();
  app.display();
}

void keyPressed() {
  if(key == ESC) key = 0;
  app.keyDown();
}

void setAppTitle(String str) {
  println(str);
  frame.setTitle(str);
}

void mousePressed() {
  app.click();
}

void mouseDragged() {
  app.drag();
}
