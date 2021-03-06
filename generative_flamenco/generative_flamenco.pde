/**
* Generative Flamenco.
* Generative Flamenco analyzes an image 
* of a couple dancing to flamenco music 
* pixel by pixel and translating it into 
* MIDI signals and sends it to Ableton Live, 
* filtered by range, scale and key.
* 
* 2013 - Tobias Treppmann
*/


import oscP5.*;
import netP5.*;
import controlP5.*;
//import rwmidi.*;
import promidi.*;



/**
*
* Sends PLAY or STOP message to Live
* Handles incoming messages:
*   /live/play
*   /live/clip/info
*   /live/volume
*   /live/tempo
*
* Sends and retrieves Tempo from Live

* LiveOSC reference: http://monome.q3f.org/browser/trunk/LiveOSC/OSCAPI.txt
* 
*/



//OSC related libraries
OscP5 oscP5;
NetAddress myRemoteLocation;

//Ports defined by LiveOSC,cannot be changed
int inPort = 9001;
int outPort = 9000;

// RWMidi device
//MidiOutput output;

// proMIDI device
Sequencer sequencer;
Song song;
Track track;
int notecount = 0;

void setupProMIDI() {
 sequencer = new Sequencer();

 MidiIO midiIO = MidiIO.getInstance();
 midiIO.printDevices();
// midiIO.closeOutput(1);
 MidiOut test = midiIO.getMidiOut(1,0);

 track = new Track("one", test);
 track.setQuantization(Q._1_4);
 track.addEvent(new Note(36, 127, 40), 0);
 track.addEvent(new Note(49, 80, 40), 1);
 track.addEvent(new Note(41, 90, 40), 2);
 track.addEvent(new Note(46, 127, 40), 3);

 song = new Song("test", 120);
 song.addTrack(track);
 song.setTempo(setTempo);
 sequencer.setSong(song);

 sequencer.start(); 
}

int[][] musicalScale = {  { 2, 4, 5, 7, 9, 11, 12 }, // Ionian
                          { 2, 3, 5, 7, 9, 10, 12 }, // Dorian
                          { 1, 3, 5, 7, 8, 10, 12 }, // Phrygian
                          { 2, 4, 6, 7, 9, 11, 12 }, // Lydian
                          { 2, 4, 5, 7, 9, 10, 12 }, // Mixolydian
                          { 2, 3, 5, 7, 8, 10, 12 }, // Aeolian (natural minor scale)
                          { 1, 3, 5, 6, 8, 10, 12 }, // Locrian
                          { 2, 4, 6, 7, 9, 10, 12 }, // Acoustic Scale
                          { 2, 4, 5, 7, 8, 10, 12 }, // Adonai malakh mode
                          { 2, 3, 6, 7, 8, 11, 12 }, // Algerian Scale
                          { 1, 3, 4, 6, 8, 10, 12 }, // Altered Scale
                          { 3, 4, 7, 8, 11, 12 }, // Augmented Scale
                          { 2, 4, 5, 7, 9, 10, 11, 12 }, // Bebop Dominant Scale
                          { 3, 5, 6, 7, 10, 12 }, // Blues Scale
                          { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 }, // Chromatic Scale
                          { 1, 4, 5, 7, 8, 11, 12 }, // Double Harmonic Scale
                          { 1, 4, 6, 8, 10, 11, 12 }, // Enigmatic Scale
                          { 1, 4, 5, 7, 8, 11, 12 }, //Flamenco Scale
                          { 2, 3, 6, 7, 8, 10, 12 }, // Gypsy Scale
                          { 2, 3, 5, 6, 8, 10, 12 }, // Half diminished Scale
                          { 2, 4, 5, 7, 8, 11, 12 }, // Harmonic Major Scale
                          { 2, 3, 5, 7, 8, 11, 12 }, // Harmonic Minor Scale
                          { 4, 6, 7, 11, 12 }, // Hirajoshi scale
                          { 2, 3, 6, 7, 8, 11, 12 }, // Hungarian Gypsy Scale
                          { 1, 5, 7, 8, 12 }, // In scale
                          { 1, 5, 7, 10, 12 }, // Insen scale
                          { 1, 5, 6, 10, 12 }, // Iwato scale
                          { 2, 3, 5, 6, 8, 9, 11, 12 }, // Octatonic scale
                          { 1, 4, 5, 6, 8, 11, 12 }, // Persian Scale
                          { 2, 4, 6, 9, 10, 12 }, // Prometheus scale
                          { 3, 4, 57, 9, 12 }, // Scale of harmonics
                          { 2, 4, 6, 8, 10, 12 }, // slendro
                          { 1, 4, 6, 7, 10, 12 }, // Tritone scale
                          { 2, 3, 6, 7, 9, 10, 12 }, // Ukrainian Dorian Scale
                          { 2, 4, 6, 8, 10, 12}, // whole tone scale
                          { 3, 5, 7, 10, 12 } // Yo Scale                          
};

int theScale = 0;
int musicalKey = 12;  // 120 = 10 octaves +- 4 notes
int setMusicalScale = 0;
int midiOutput = 0;


int pitchValue(float pitch) {  
  int note = 0;
  /* original range: 0-127 all midi keys */
  if(filterByRange) {
    pitch = map(pitch, 0, 255, 0, 128); // map to entire MIDI spectrum
  } else {
    pitch = map(pitch, 0, 255, minRange, maxRange);  // map to range
  }
  println("pitch: " + int(pitch) + " filterByRange = " + filterByRange);
//  println("musicalScale[0][0]: " + musicalScale[0][0]);
  // check if the note is in the scale
  int numOctaves = 10;
//  int musicalKey = 3;
//  print("does it match any of the following? : ");
//  for(int k = 0; k < numOctaves; k++) {
//    for(int l = 0; l < musicalScale[0].length; l++) {
//       print(musicalScale[0][l]*k+musicalKey + ", ");
//      }
//    }
  
  for(int i = 0; i < numOctaves; i++) {
    for(int j = 0; j < musicalScale[setMusicalScale].length; j++) {
     if(int(pitch) == musicalScale[setMusicalScale][j]*i+musicalKey) {
       if(filterByRange) {
         if(int(pitch) > minRange && int(pitch) < maxRange) {
           note = int(pitch);
         }
       } else {
         note = int(pitch);
       }
      }
    }
  }
  println("note: " + note);
  
  
  return note; 
  
//  return scale[cellValue(x, y)] + (x + y) % 3 * 12 + 40;
}


int velocityValue(float velocity) {
  return int(map(velocity,0,255,25,100));
}

int noteDuration(float duration) {
 duration = map(duration, 0, 100, 0, 5);
 double mappedDuration = 5*(Math.pow(2,duration));
 int returnDuration = (int) mappedDuration;
 return returnDuration; 
}

void outputCell(float pitch, float velocity, float duration) {
  int pitchvalue = pitchValue(pitch);
//  if(abs(pitchvalue-prevPitchValue)>3) { // check for a key difference of at least a third
    if(pitchvalue != prevPitchValue) {
//      output.sendNoteOn(0, pitchValue(pitch), velocityValue(velocity));
      track.addEvent(new Note(pitchValue(pitch), velocityValue(velocity), noteDuration(duration)), ++notecount);
      println("pitchvalue: " + pitchValue(pitch));
      println("velocityvalue: " + velocityValue(velocity));
      println("duration: " + noteDuration(duration));
    }  
//  }
  prevPitchValue = pitchvalue;
}

int prevPitchValue = 0;

// getTempo variable, set by standard to 120.0bpm
float getTempo = 120.0; //bpm
float framerate = 2; // ~120bpm
float framerateMultiplier = 1;
float setTempo = 120.0;
float minRange = 0.0;
float maxRange = 127.0;
boolean filterByRange = true; 
/* 
  color is mapped to 128 notes, but only the ones in the range are played = fewer notes played
  if false == map note to range = more notes played
  
*/

// image variables
PImage a;
int[] aPixels;
int direction = 1;
boolean onetime = true;
float signal;
int imageWidth = 612;
int imageHeight = 612;

int cellValue(int x, int y) {
  return (x + y) % NUM_VALUES;
}

int pitch;
int velocity;

static final int NUM_VALUES = 8;

//GUI library
ControlP5 controlP5;
Slider setTempoSlider;
Range setRangeSlider;
DropdownList dlSpeed;
DropdownList dlMusicalKey;
DropdownList dlMusicalScale;
RadioButton rRangeBehavior;
boolean controlP5isVisible = true;

void setup() {
  size(imageWidth,imageHeight);
  
  setupProMIDI();
  
  //OSC Server
  oscP5 = new OscP5(this,inPort);
  //Remote address
  myRemoteLocation = new NetAddress("localhost",outPort);
  
  //GUI settings and buttons
  frameRate(framerate*framerateMultiplier);
  controlP5 = new ControlP5(this);
  controlP5.addButton("Play");
  controlP5.addButton("Stop");
  setTempoSlider = controlP5.addSlider("setTempo")
            .setRange(0,255)
            .setValue(120)
            .setSize(240,19)
            ;
            
  setRangeSlider = controlP5.addRange("setRange")
            .setRange(1,128)
            .setRangeValues(1,128)
            .setNumberOfTickMarks(128)
            .setSize(398,20)
            .setPosition(10,0)
            .showTickMarks(false)
            .snapToTickMarks(true) 
            ;
  
  dlSpeed = controlP5.addDropdownList("Speed")
    .setPosition(10, 80)
            .setSize(69,240)
            .setItemHeight(20)
            .setBarHeight(20)
            ;
  for (int i=0;i<11;i++) {
    double multip = Math.pow(2,i);
    if(multip < 1 ){multip++;}
    dlSpeed.addItem(multip + "x", i);
  }
  dlSpeed.setIndex(5);
  
  dlMusicalKey = controlP5.addDropdownList("Key")
            .setPosition(90, 80)
            .setSize(69,260)
            .setItemHeight(20)
            .setBarHeight(20);
            ;
  dlMusicalKey.addItem("C", 0);
  dlMusicalKey.addItem("C#", 1);
  dlMusicalKey.addItem("D", 2);
  dlMusicalKey.addItem("D#", 3);
  dlMusicalKey.addItem("E", 4);
  dlMusicalKey.addItem("F", 5);
  dlMusicalKey.addItem("F#", 6);
  dlMusicalKey.addItem("G", 7);
  dlMusicalKey.addItem("G#", 8);
  dlMusicalKey.addItem("A", 9);
  dlMusicalKey.addItem("A#", 10);
  dlMusicalKey.addItem("B", 11);  
  dlMusicalKey.setIndex(0);
  
  dlMusicalScale = controlP5.addDropdownList("Scale")
            .setPosition(168, 80)
            .setSize(119,260)
            .setItemHeight(20)
            .setBarHeight(20);
            ;
  dlMusicalScale.addItem("Ionian", 0);
  dlMusicalScale.addItem("Dorian", 1);
  dlMusicalScale.addItem("Phrygian", 2);
  dlMusicalScale.addItem("Lydian", 3);
  dlMusicalScale.addItem("Mixolydian", 4);
  dlMusicalScale.addItem("Aeolian", 5);
  dlMusicalScale.addItem("Locrian", 6);
  
  dlMusicalScale.addItem("Acoustic Scale", 7); 
  dlMusicalScale.addItem("Adonai malakh mode", 8);
  dlMusicalScale.addItem("Algerian Scale", 9);
  dlMusicalScale.addItem("Altered Scale", 10);
  dlMusicalScale.addItem("Augmented Scale", 11);
  dlMusicalScale.addItem("Bebop Dominant Scale", 12);
  dlMusicalScale.addItem("Blues Scale", 13);
  dlMusicalScale.addItem("Chromatic Scale", 14);
  dlMusicalScale.addItem("Double Harmonic Scale", 15);
  dlMusicalScale.addItem("Enigmatic Scale", 16);
  dlMusicalScale.addItem("Flamenco Scale", 17);
  dlMusicalScale.addItem("Gypsy Scale", 18);
  dlMusicalScale.addItem("Half diminished Scale", 19);
  dlMusicalScale.addItem("Harmonic Major Scale", 20);
  dlMusicalScale.addItem("Harmonic Minor Scale", 21);
  dlMusicalScale.addItem("Hirajoshi scale", 22);
  dlMusicalScale.addItem("Hungarian Gypsy Scale", 23);
  dlMusicalScale.addItem("In scale", 24);
  dlMusicalScale.addItem("Insen scale", 25);
  dlMusicalScale.addItem("Iwato scale", 26);
  dlMusicalScale.addItem("Octatonic scale", 27);
  dlMusicalScale.addItem("Persian Scale", 28);
  dlMusicalScale.addItem("Prometheus scale", 29);
  dlMusicalScale.addItem("Scale of harmonics", 30);
  dlMusicalScale.addItem("Slendro", 31);
  dlMusicalScale.addItem("Tritone scale", 32);
  dlMusicalScale.addItem("Ukrainian Dorian Scale", 33);
  dlMusicalScale.addItem("whole tone scale", 34);
  dlMusicalScale.addItem("Yo Scale", 35);
  dlMusicalScale.setIndex(0);
   
  rRangeBehavior = controlP5.addRadioButton("RangeBehavior")
         .setPosition(293,58)
         .setSize(40,20)
         .setColorForeground(color(120))
         .setColorActive(color(255))
         .setColorLabel(color(255))
         .setItemsPerRow(2)
         .setSpacingColumn(85)
         .addItem("Filter_By_Range",0)
         .addItem("Map_To_Range",1)
         .activate(0)
         ;
  
  for(Toggle t:rRangeBehavior.getItems()) {
       t.captionLabel().style().moveMargin(-7,0,0,-3);
       t.captionLabel().style().movePadding(7,0,0,3);
       t.captionLabel().style().backgroundWidth = 45;
       t.captionLabel().style().backgroundHeight = 13;
     }
  
  // the image
  aPixels = new int[imageWidth*imageHeight];
  noFill();
  stroke(255); 
  a = loadImage("flamenco.png");
  println(a);
  println("a.width: " + a.width + " a.height: " + a.height);
  for(int i=0; i<a.width*a.height; i++) {
    aPixels[i] = a.pixels[i];
  }
  
  //OSC address mapping
  oscP5.plug(this,"incomingHandlerPlay","/live/play");
  oscP5.plug(this,"incomingHandlerClipInfo","/live/clip/info");
  oscP5.plug(this,"incomingHandlerVolume","/live/volume");
  oscP5.plug(this,"incomingHandlergetTempo","/live/tempo");
  oscP5.plug(this,"incomingHandlersetTempo","/live/tempo");
  
  // initialize the getTempo from DAW, which will also update the framerate accordingly
  getTempo();
}

void draw() {
  background(0);
  imageToMusic();
  println("framerate: " + frameRate);
}

void controlEvent(ControlEvent theEvent) {
  // DropdownList is of type ControlGroup.
  // A controlEvent will be triggered from inside the ControlGroup class.
  // therefore you need to check the originator of the Event with
  // if (theEvent.isGroup())
  // to avoid an error message thrown by controlP5.

  if (theEvent.isGroup()) {
    // capture events from the Speed dropDownList
    // sets the framerate at a multiple of the tempo to speed up the tone generation without going off the beat
    if(theEvent.getGroup() == dlSpeed) {
      // check if the Event was triggered from a ControlGroup
      double theVal = Math.pow(2,theEvent.getGroup().getValue());
      framerateMultiplier = (float) theVal; 
      setFrameRate(setTempo);
      println("event from group : "+theEvent.getGroup().getValue()+" from "+theEvent.getGroup());
    }
    // capture events from the MusicalKey dropDownList and set the musicalKey accordingly
    if(theEvent.getGroup() == dlMusicalKey) {
     musicalKey = int(theEvent.getGroup().getValue());
     if(musicalKey < 1 || musicalKey > 12) {
       musicalKey = 12;
     } 
     println("KEY: " + musicalKey);
    }
    
    if(theEvent.getGroup() == dlMusicalScale) {
     setMusicalScale = int(theEvent.getGroup().getValue()); 
    }
  }
  if (theEvent.isFrom("setRange")) {
    // min and max values are stored in an array.
    // access this array with controller().arrayValue().
    // min is at index 0, max is at index 1.
    minRange = int(theEvent.getController().getArrayValue(0));
    maxRange = int(theEvent.getController().getArrayValue(1));
    println("range update, done.");
  } 
  if (theEvent.isFrom(rRangeBehavior)) {
    if(theEvent.getValue() == 0.0) {
     filterByRange = true; 
    } else {
     filterByRange = false;
    }
  }
  else if (theEvent.isController()) {
    println("event from controller : "+theEvent.getController().getValue()+" from "+theEvent.getController());
  }
}

/**
*  Display and analyze the image
*/
void imageToMusic() {
  if (signal > width*height-1 ||
    signal < 0) {
    direction = direction * -1;
  }
 
  if(mousePressed) {
    if(mouseY > height-1) {
      mouseY = height-1;
    }
    if(mouseY < 0) {
      mouseY = 0;
    }
    signal = mouseY*width+mouseX;
  } else {
    signal += (0.33*direction); 
  }
   
   
  loadPixels();
  for (int i=0; i<width*height; i++) {
    pixels[i] = aPixels[i]; 
  }
  updatePixels();
  rect(signal%width-5, int(signal/width)-5, 10, 10);
  point(signal%width, int(signal/width));
    
  // with portamento on the frequency will change smoothly
  float pitch = brightness(aPixels[int(signal)]);
  float velocity = saturation(aPixels[int(signal)]);
  float duration = brightness(aPixels[int(signal)]);
  //aPixels[int(signal)];
  outputCell(pitch, velocity, duration);
  // pan always changes smoothly to avoid crackles getting into the signal
  // note that we could call setPan on out, instead of on sine
  // this would sound the same, but the waveforms in out would not reflect the panning
  float pan = map(pixels[int(signal)], 0, width, -1, 1);
  //  sine.setPan(pan);
   
  println ("\n brightness= " + brightness (aPixels[int(signal)]) + "   hue= " + hue (aPixels[int(signal)]));
}

void keyPressed() {
 if(key == ' ') {
   if(controlP5isVisible) {
     controlP5.hide();
     controlP5isVisible = false;
   } else {
     controlP5.show();
     controlP5isVisible = true;
   }
 } 
}

/**
* sets the FrameRate based on the DAW getTempo
*/
void setFrameRate(float getTempo) {
  float theFrameRate = getTempo/60;
  frameRate(theFrameRate*framerateMultiplier); 
  println("framerate * multiplier: " + theFrameRate*framerateMultiplier);
}

/**
* implements button click handler
* button: play
*
*/
void Play() {
  println("clicked play");
  OscMessage myMessage = new OscMessage("/live/play");
  oscP5.send(myMessage, myRemoteLocation); 
}

/**
* implements button click handler
* button: stop
*
*/
void Stop() {
  println("clicked stop");
  OscMessage myMessage = new OscMessage("/live/stop");
  oscP5.send(myMessage, myRemoteLocation);
 
}

/**
* sends the OSC message to request the getTempo information in bpm
*/
void getTempo() {
  // get the bpm
  OscMessage myMessage = new OscMessage("/live/tempo");
  oscP5.send(myMessage, myRemoteLocation);
}

/**
* retrieves the value from the setTempo slider, sets the tempo accordingly in Processing and Live
*/
void setTempo(float theTempo) {
  setTempo = theTempo; 
  // set the bpm
  OscMessage myMessage = new OscMessage("/live/tempo");
  myMessage.add(theTempo);
  oscP5.send(myMessage, myRemoteLocation);
}

/**
* implements incoming message handler.
* address: /live/play
*
* @param int state Current state of the song
*/
void incomingHandlerPlay(int state){
  switch(state){
    case 1:
      println("Song STOP");
      break;
    case 2:
      println("Song PLAY");
      break;
  }
}
/**
* implements incoming message handler.
* address: /live/clip/info
*
* @param int track Track number
* @param int clip Clip number
* @param int state Current state of the clip
*/
void incomingHandlerClipInfo(int track,int clip,int state){
  switch(state){
      //STOP
      case 1:
        println("Stopped clip - Track:"+track+" Clip:"+clip);
        break;
      //PLAY
      case 2:
        println("Playing clip - Track:"+track+" Clip:"+clip);
        break;
      //LAUNCHED
      case 3:
        println("Triggered clip - Track:"+track+" Clip:"+clip); 
       break; 
    }
}
/**
* implements incoming message handler.
* address: /live/volume
*
* @param int track Track number
* @param float value The actual volume of the track
*/
void incomingHandlerVolume(int track,float value){
  println("Track:" + track + " vol:"+value);    
}

void incomingHandlergetTempo(float receivedTempo){
  getTempo = receivedTempo;
  setFrameRate(getTempo);
  setTempoSlider.setValue(getTempo);
  setTempo(getTempo);
  println("Bpm:" + getTempo);    
}

void incomingHandlersetTempo(float receivedTempo) {
  println("setting tempo was successful");
  incomingHandlergetTempo(receivedTempo);
}
/*
* OSC event handler
*/
void oscEvent(OscMessage theOscMessage) {
  
  if(theOscMessage.isPlugged()==false) {
    //we just print the not plugged messages.
    println("[NOT HANDLED] addr:" + theOscMessage.addrPattern() + " | typetag: " + theOscMessage.typetag());
  }
}
