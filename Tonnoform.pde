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

InstrumentPage instPage;

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
  app.keyDown();
}

void mousePressed() {
  app.click();
}

void mouseDragged() {
  app.drag();
}
