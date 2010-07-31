Rob.Vox
========

#### Realtime Audio Effects Unit ####

Requires [ChucK](http://chuck.cs.princeton.edu/) to run.

Can turn your voice into robot vocals.

There are 2 blocks of code you'll want to edit to enable your own MIDI device and to customize your own presets:

#### Knobs ####

* You will have to change the MIDI CC numbers on the knobs, so this script works with your MIDI device.
* You can find the MIDI CC values by reading the ChucK output window as you turn a knob on your MIDI controller.
* Take note of the first and second values, and replace the first 2 parameters in the createMidiKnob() functions

createMidiKnob( 177, 13, 0, 4 ) @=> MIDIKnob masterGainKnob;

#### Presets ####

* With the following code, you can create your own presets. Look at the createPreset() function for reference.
* If you add or remove presets, make sure to change the number 10 below.

10 => int numPresets;
createPreset( 0  , 0  , 1  , 1  , 0  ) @=> presetsArray[0]; // default - no effects
createPreset( .05, .05, .90, 1 , .03 ) @=> presetsArray[1];
