Rob.Vox
========

#### Realtime Audio Effects Unit ####

Requires [ChucK](http://chuck.cs.princeton.edu/) to run.

Can turn your voice into robot vocals.

There are 2 blocks of code you'll want to edit to enable your own MIDI device and to customize your own presets:

#### Knobs ####

// You will have to change the MIDI CC numbers on the knobs, so this script works with your MIDI device.
// You can find the MIDI CC values by reading the ChucK output window as you turn a knob on your MIDI controller.
// Take note of the first and second values, and replace the first 2 parameters in the createMidiKnob() functions

// set up custom midi knobs
createMidiKnob( #### 177 ####, #### 13 ####, 0, 4 ) @=> MIDIKnob masterGainKnob;

#### Presets ####

// With the following code, you can create your own presets. Look at the createPreset() function for reference.
// If you add or remove presets, make sure to change the number 10 below.

// build custom preset objects
10 => int numPresets;
Preset presetsArray[ numPresets ];
createPreset( 0  , 0  , 1  , 1  , 0  ) @=> presetsArray[0];
createPreset( .05, .05, .90, 1 , .03 ) @=> presetsArray[1];
createPreset( .10, .78, 1.3, 1 , .01 ) @=> presetsArray[2];
createPreset( .01, .78, 1.4, 1 , .01 ) @=> presetsArray[3];
createPreset( .16, .78, 1.5, 1 , .02 ) @=> presetsArray[4];
createPreset( .05, .61, 1.5, 1 , .02 ) @=> presetsArray[5];
createPreset( .03, .48, 2.3, 1 , .04 ) @=> presetsArray[6];
createPreset( .02, .94, .84, 1 , .02 ) @=> presetsArray[7];
createPreset( .024,.87, 1.1, 1 , .03 ) @=> presetsArray[8];
createPreset( .04, .81, 1.4, 1 , .04 ) @=> presetsArray[9];
