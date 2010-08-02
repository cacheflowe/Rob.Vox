Rob.Vox
========

#### Realtime Audio Effects Unit ####

Requires [ChucK](http://chuck.cs.princeton.edu/) to run.

Can turn your voice into robot vocals using pitch shift, delay, and reverb.

There are 2 blocks of code you'll likely want to edit to enable your own MIDI device and to customize your own presets:

#### MIDI Devices ####

Rob.Vox currently registers with every MIDI device that's recognized by your operating system. This should have no impact on other MIDI-capable software.

#### Knobs ####

* You will have to change the MIDI CC numbers on the knobs for Rob.Vox to work with your MIDI device(s).
* You can find the MIDI CC values by reading the ChucK console window as you turn a knob on your MIDI controller.
* Take note of the first and second values, and replace the first 2 parameters in the createMidiKnob() functions:

createMidiKnob( 177, 13, 0, 4 ) @=> MIDIKnob masterGainKnob;

* The 3rd and 4th parameters are the low and high value for the knob, which are applied to the effect parameter. You can change these too, but beware of overloading ChucK, for your ears' sake!

#### Presets ####

* With the following code, you can create your own presets. Look at the createPreset() function for reference.
* If you add or remove presets, make sure to change the number 10 below.

10 => int numPresets;

createPreset( 0  , 0  , 1  , 1  , 0  ) @=> presetsArray[0]; // default - no effects

createPreset( .024,.87, 1.1, 1 , .03 ) @=> presetsArray[8]; // fun robot effect
