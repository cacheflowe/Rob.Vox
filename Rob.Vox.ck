// ---------------------------------------------------------
// Get all MIDI inputs
// ---------------------------------------------------------

// get number of devices, and load them up into arrays
getNumberOfMidiInputDevices() => int numMidiDevices;
<<< "Found", numMidiDevices, "MIDI devices" >>>;

MidiIn midiInputs[numMidiDevices];
MidiMsg midiDataMessages[numMidiDevices];

for( 0 => int i; i < numMidiDevices; i++ )
{
	MidiIn midiInput;
	MidiMsg midiDataMsg;
	
	if( midiInput.open( i ) ) {
		<<< "Loaded MIDI device:", midiInput.num(), " -> ", midiInput.name() >>>;
		midiInput @=> midiInputs[i];
		midiDataMsg @=> midiDataMessages[i];
	}
}


// ---------------------------------------------------------
// Create audio signal path
// ---------------------------------------------------------
// to re-implement: Gain midiEnvGain => , PitShift delayPitchShift => g

adc => Dyno dyno => HPF highpassFilter => PitShift pitchShift => Gain g => Chorus chorus => JCRev reverb => Gain masterGain => dac;
g => Gain feedback => DelayL delay => g;	// feedback for delay


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
	float chorusMix;
}

// preset object "constructor"
function Preset createPreset( float delayTime, float delayAmount, float pitchLevel, float pitchMix, float reverbAmount, float chorusMix )
{
	Preset preset;
	delayTime => preset.delayTime;
	delayAmount => preset.delayAmount;
	pitchLevel => preset.pitchLevel;
	pitchMix => preset.pitchMix;
	reverbAmount => preset.reverbAmount;
	chorusMix => preset.chorusMix;
	return preset;
}

// build custom preset objects
10 => int numPresets;
Preset presetsArray[ numPresets ];
createPreset( 0  , 0  , 1  , 1  , 0 , 0 ) @=> presetsArray[0]; // default - no effects
createPreset( .05, .05, .90, 1 , .03, 0 ) @=> presetsArray[1];
createPreset( .10, .78, 1.3, 1 , .01, 0 ) @=> presetsArray[2];
createPreset( .01, .78, 1.4, 1 , .01, 0 ) @=> presetsArray[3];
createPreset( .16, .78, 1.5, 1 , .02, 0 ) @=> presetsArray[4];
createPreset( .05, .61, 1.5, 1 , .02, 0 ) @=> presetsArray[5];
createPreset( .03, .48, 2.3, 1 , .04, 0 ) @=> presetsArray[6];
createPreset( .02, .94, .84, 1 , .02, 0 ) @=> presetsArray[7];
createPreset( .024,.87, 1.1, 1 , .03, 0 ) @=> presetsArray[8];
createPreset( .04, .81, 1.4, 1 , .04, 0 ) @=> presetsArray[9];

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
	chorus.mix( curPreset.chorusMix );
}


// ---------------------------------------------------------
// Create MIDI knob objects 
// ---------------------------------------------------------

// midi cc data object class - handles
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
createMidiKnob( 190, 31, 0, 1 ) @=> MIDIKnob chorusKnob;


// ---------------------------------------------------------
// Initialize 
// ---------------------------------------------------------

// set default preset to initialize effects params
applyPreset(0);
// set hi pass filter to cut out crappy vocal low-end
200 => highpassFilter.freq;
// set up limiter
dyno.limit();
dyno.thresh ( 0.4 );
// set up chorus
chorus.modDepth( .1 );
chorus.mix( 0.2 );

// ---------------------------------------------------------
// Audio Loop 
// ---------------------------------------------------------
while( true )
{
	// run in a 5ms loop 
	5::ms => now;
	// loop through midi devices
	for( 0 => int i; i < numMidiDevices; i++ )
	{
		// get refs to midi device and data message
		midiInputs[i] @=> MidiIn midiInput;
		midiDataMessages[i] @=> MidiMsg midiDataMsg;

		// detect the midi message
		while( midiInput.recv( midiDataMsg ) )
		{
			// print out incoming midi data
			<<< "incoming MIDI data: ", midiDataMsg.data1, midiDataMsg.data2, midiDataMsg.data3 >>>;
			
			
			// set master input gain
			if( matchMidiKnobToMidiSignal( masterGainKnob, midiDataMsg ) == 1 )
			{
				getCurrentKnobValue( masterGainKnob, midiDataMsg ) => masterGain.gain;
				<<< "master input vol = ", getCurrentKnobValue( masterGainKnob, midiDataMsg ) >>>;
			}
			
			// set pitch shift
			if( matchMidiKnobToMidiSignal( pitchShiftKnob, midiDataMsg ) == 1 )
			{
				pitchShift.shift( getCurrentKnobValue( pitchShiftKnob, midiDataMsg ) );
				<<< "pitch shift = ", getCurrentKnobValue( pitchShiftKnob, midiDataMsg ) >>>;
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
			
			// set chorus mix
			if( matchMidiKnobToMidiSignal( chorusKnob, midiDataMsg ) == 1 )
			{
				chorus.mix( getCurrentKnobValue( chorusKnob, midiDataMsg ) );
				<<< "chorus mix = ", getCurrentKnobValue( chorusKnob, midiDataMsg ) >>>;
			}
			
			// set preset
			if( matchMidiKnobToMidiSignal( presetKnob, midiDataMsg ) == 1 )
			{
				// get preset index by casting to int and thus rounding the knob value
				getCurrentKnobValue( presetKnob, midiDataMsg ) $ int => int presetIndex;
				applyPreset( presetIndex );
				<<< "preset index = ", presetIndex >>>;
			}
		}
	}
}


// ---------------------------------------------------------
// Helper Functions 
// ---------------------------------------------------------

function int getNumberOfMidiInputDevices()
{
	0 => int numDevices;
	for( 0 => int i; i < 99; i++ )
	{
		MidiIn midiDevice;		
		if( midiDevice.open( i ) )
			numDevices++;
		else
			return numDevices;
	}
}

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


