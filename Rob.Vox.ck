// ---------------------------------------------------------
// Get MIDI input
// ---------------------------------------------------------
0 => int device;
if( me.args() ) me.arg(0) => Std.atoi => device;
MidiIn midiInput;
MidiMsg midiDataMsg;
if( !midiInput.open( device ) ) me.exit();
<<< "MIDI device:", midiInput.num(), " -> ", midiInput.name() >>>;


// ---------------------------------------------------------
// Create audio signal path
// ---------------------------------------------------------
adc => Gain midiEnvGain => HPF highpassFilter => PitShift pitchShift => Dyno dyno => Gain g => JCRev reverb => Gain masterGain => dac;
g => Gain feedback => DelayL delay => PitShift delayPitchShift => g;	// feedback for delay


// ---------------------------------------------------------
// Define Effects Presets
// ---------------------------------------------------------

// preset class
class Preset { 
	float delayTime; 
	float delayAmount; 
	float pitchLevel; 
	float pitchMix; 
	float reverbAmount; 
}

// preset object "constructor"
function Preset createPreset( float delayTime, float delayAmount, float pitchLevel, float pitchMix, float reverbAmount )
{
	Preset preset;
	delayTime => preset.delayTime;
	delayAmount => preset.delayAmount;
	pitchLevel => preset.pitchLevel;
	pitchMix => preset.pitchMix;
	reverbAmount => preset.reverbAmount;
	return preset;
}

// build custom preset objects
10 => int numPresets;
Preset presetsArray[ numPresets ];
createPreset( 0  , 0  , 1  , 1  , 0  ) @=> presetsArray[0]; // default - no effects
createPreset( .05, .05, .90, 1 , .03 ) @=> presetsArray[1];
createPreset( .10, .78, 1.3, 1 , .01 ) @=> presetsArray[2];
createPreset( .01, .78, 1.4, 1 , .01 ) @=> presetsArray[3];
createPreset( .16, .78, 1.5, 1 , .02 ) @=> presetsArray[4];
createPreset( .05, .61, 1.5, 1 , .02 ) @=> presetsArray[5];
createPreset( .03, .48, 2.3, 1 , .04 ) @=> presetsArray[6];
createPreset( .02, .94, .84, 1 , .02 ) @=> presetsArray[7];
createPreset( .024,.87, 1.1, 1 , .03 ) @=> presetsArray[8];
createPreset( .04, .81, 1.4, 1 , .04 ) @=> presetsArray[9];

// set all effects to a preset's defaults
function void applyPreset( int presetIndex )
{
	// get preset from index
	presetsArray[ presetIndex ] @=> Preset curPreset;
	// apply preset
	pitchShift.mix( curPreset.pitchMix );
	pitchShift.shift( curPreset.pitchLevel );
	reverb.mix( curPreset.reverbAmount );
	curPreset.delayTime::second => delay.max => delay.delay;
	curPreset.delayAmount => feedback.gain;
}


// ---------------------------------------------------------
// Create MIDI knob objects 
// ---------------------------------------------------------

// midi cc data object class
class MIDIKnob { 
	int midiIdOne; 
	int midiIdTwo; 
	float minValue; 
	float maxValue; 
}

// midi knob object "constructor"
function MIDIKnob createMidiKnob( int knobIdOne, int knobIdTwo, float minVal, float maxVal )
{
	MIDIKnob newKnob;
	knobIdOne => newKnob.midiIdOne;
	knobIdTwo => newKnob.midiIdTwo;
	minVal => newKnob.minValue;
	maxVal => newKnob.maxValue;
	return newKnob;
}

// set up custom midi knobs
createMidiKnob( 177, 13, 0, 4 ) @=> MIDIKnob masterGainKnob;
createMidiKnob( 178, 13, 0, numPresets - 1 ) @=> MIDIKnob presetKnob;
createMidiKnob( 179, 13, 0.44, 4 ) @=> MIDIKnob pitchShiftKnob;
createMidiKnob( 180, 13, 0, 1 ) @=> MIDIKnob delayFeedbackKnob;
createMidiKnob( 181, 13, 0.03, 0.2 ) @=> MIDIKnob delayTimeKnob;
createMidiKnob( 182, 13, 0, 0.2 ) @=> MIDIKnob reverbKnob;
createMidiKnob( 182, 13, 0, 0.2 ) @=> MIDIKnob hpfKnob;


// ---------------------------------------------------------
// Initialize 
// ---------------------------------------------------------
applyPreset(0);
200 => highpassFilter.freq;


// ---------------------------------------------------------
// Audio Loop 
// ---------------------------------------------------------
while( true )
{
	// run in a 5ms loop 
	5::ms => now;
	// detect the midi message
	while( midiInput.recv(midiDataMsg) )
	{
		// print out incoming midi data
		<<< "incoming MIDI data: ", midiDataMsg.data1, midiDataMsg.data2, midiDataMsg.data3 >>>;
		
		
		// set master gain
		if( matchMidiKnobToMidiSignal( masterGainKnob, midiDataMsg ) == 1 )
		{
			getCurrentKnobValue( masterGainKnob, midiDataMsg ) => masterGain.gain;
			<<< "masterVolKnob", getCurrentKnobValue( masterGainKnob, midiDataMsg ) >>>;
		}
		
		// set pitch shift
		if( matchMidiKnobToMidiSignal( pitchShiftKnob, midiDataMsg ) == 1 )
		{
			pitchShift.shift( getCurrentKnobValue( pitchShiftKnob, midiDataMsg ) );
			<<< "pitchShiftVal", getCurrentKnobValue( pitchShiftKnob, midiDataMsg ) >>>;
		}
		
		// set reverb
		if( matchMidiKnobToMidiSignal( reverbKnob, midiDataMsg ) == 1 )
		{
			reverb.mix( getCurrentKnobValue( reverbKnob, midiDataMsg ) );
			<<< "reverb mix = ", getCurrentKnobValue( reverbKnob, midiDataMsg ) >>>;
		}
		
		// set delay mix
		if( matchMidiKnobToMidiSignal( delayFeedbackKnob, midiDataMsg ) == 1 )
		{
			feedback.gain( getCurrentKnobValue( delayFeedbackKnob, midiDataMsg ) );
			<<< "delay feedback = ", getCurrentKnobValue( delayFeedbackKnob, midiDataMsg ) >>>;
		}
		
		// set delay time
		if( matchMidiKnobToMidiSignal( delayTimeKnob, midiDataMsg ) == 1 )
		{
			getCurrentKnobValue( delayTimeKnob, midiDataMsg )::second => delay.max => delay.delay;
			<<< "delay time = ", getCurrentKnobValue( delayTimeKnob, midiDataMsg ) >>>;
		}
		
		// set preset
		if( matchMidiKnobToMidiSignal( presetKnob, midiDataMsg ) == 1 )
		{
			// get preset index by casting to int and thus rounding the knob value
			getCurrentKnobValue( presetKnob, midiDataMsg ) $ int => int presetIndex;
			applyPreset( presetIndex );
			<<< "preset index: ", presetIndex >>>;
		}
	}
}


// ---------------------------------------------------------
// Helper Functions 
// ---------------------------------------------------------

function int matchMidiKnobToMidiSignal( MIDIKnob knob, MidiMsg midiData )
{
	if( midiData.data1 == knob.midiIdOne &&  midiData.data2 == knob.midiIdTwo )
		return 1;
	else
		return 0;
}

function float getCurrentKnobValue( MIDIKnob knob, MidiMsg midiData )
{
	return knob.minValue + convertMidiToPercent( midiData.data3 ) * knob.maxValue;
}

function float convertMidiToPercent( float midiValue )
{
	midiValue / 127 => float percent;
	return percent;
}


