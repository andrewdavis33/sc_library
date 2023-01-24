// Slowdowner

// Set Sound Source
(
var file = "puccini.wav";
var path = "/Users/adavis/Desktop" +/+ file;
~b = Buffer.read(s, path);
)

// Set parameters
(
~trigNoteNum = 94; //

~speedControlVal = 1; // The initial speed
~speedControlNum = 44; // The CC number you will use to control the speed

~speedBendVal = 1;

// Three types of speed control
// 0 -> slow down with continuous controller like knob
// 1 -> speed up with continuous controller like knob
// 2 -> speed up/slow down with bend
~type = 2;
)

// Initialize MIDI
// Execute once
(
SynthDef(\speed, {
	arg out = 0, speed = 0, bufnum, amp = 1;
	var sig = PlayBuf.ar(2, bufnum, Lag3.kr(speed, 0.25), doneAction: 2);
	Out.ar(out, sig * amp);
}).add;

// Initialize MIDI
MIDIClient.init;
MIDIIn.connectAll;

~mapList = List.new;
~mapList.add({|val| val.linlin(0, 127, 1, 0)}); // slow down with cc
~mapList.add({|val| val.linlin(0, 127, 1, 2)}); // speed up with cc
~mapList.add({|val| val.linlin(0, 16384, 0, 2)}); // speed up/slow down with bend

~ccList = List.new;
~ccList.add(
	MIDIFunc.cc({
		// Set the initial speed before triggering the audio file
		|val, num, chan, src|
		if ((~speedControlNum == num) && (~type != 2)) {
			~speedControlVal = ~mapList[~type].(val);
		}
	}).permanent_(true);
);

~ccList.add(
	MIDIFunc.bend({
		|val, chan, src|
		if (~type == 2) {
			~speedBendVal = ~mapList[~type].(val);
		}
	}).permanent_(true);
);

~ccList.add(
	MIDIFunc.cc({
		|val, num, chan|
		("Controller number:" + num.asString + "| Value number:" + val.asString).postln;
	}).permanent_(true);
);

~ccList.add(
	// Buttons on MIDI controllers treated as Note On messages it seems
	MIDIFunc.noteOn({
		|val, num, chan|
		("Note number:" + num.asString + "| Value number:" + val.asString).postln;
	}).permanent_(true);
);

~ccList.add(
	MIDIFunc.bend({
		|val, chan, src|
		("Bend Value:" + val.asString).postln;
	}).permanent_(true);
);
)

// Play
(
// Start sound file
MIDIFunc.noteOn({
	|val, num, chan|
	~synth = Synth(\speed, [
		\bufnum, ~b,
		\speed, if(~type == 2, {~speedBendVal}, {~speedControlVal})
	]);
});

// Change pitch for knobs
MIDIFunc.cc({
	|val, num, chan, src|
	if ((~speedControlNum == num) && (~type != 2)) {
		~synth.set(\speed, ~mapList[~type].(val));
	};
});

// Change pitch for bend
MIDIFunc.bend({
	|val, chan, src|
	if (~type == 2) {
		~synth.set(\speed, ~mapList[~type].(val));
	};
});
)

// Free permanent cc functions
~ccList.dump;

(
~ccList.do({|midiFunc| midiFunc.free});
~ccList.clear;
)
