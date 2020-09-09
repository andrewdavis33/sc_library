/* Digital closed hi-hat sound
 * By Andrew Davis
 *
 * Hi-hat is built using a combination of tonal and noise components.  Further
 * realism is created by shaping the frequency content of the instrument over
 * time using a bandpass filter.
 */

(
SynthDef(\closedHat, {
	arg out = 0, amp = 0.1, q = 10;
	var sig, env;

	// Add noise element to sound
	sig = WhiteNoise.ar(1);

	// Add tonal elements to sound
	20.do({
		var randFreq = Rand(5000, 12000);
		sig = sig + SinOsc.ar(randFreq, mul: 12000/randFreq * 0.1);
	});

	// Moving filter to change the harmonic content over time
	sig = BPF.ar(sig, XLine.kr(Rand(9000, 10000), 5000, 0.035) , 1/(q + (amp * 10)), mul: q/2);

	// Compress and apply apply amplitude envelope
	sig = Compander.ar(sig, sig, slopeAbove: 1/3);
	env = Env([0, amp, amp * 0.75, 0], [0.001, 0.003, 0.01], 'sine');
	env = EnvGen.kr(env, doneAction: 2);
	sig = sig * env;
	Out.ar(out, sig ! 2)
}).add;
)

// Add a little reverberation
(
SynthDef(\reverb, {
	arg in, out = 0;
	var sig;
	sig = In.ar(in, 2);
	sig = FreeVerb.ar(sig, 0.15, 0.2);
	Out.ar(out, sig);
}).add;
)

(
~effectsBus = Bus.audio(s, 2);
Synth(\reverb, [\in, ~effectsBus]);
)

// Play a pattern with the hi-hat
(
var tempo = 110;
var tc = TempoClock(tempo/60);
Pbind(
	\instrument, \closedHat,
	\amp, Pseq([0.2, 0.05, 0.07, 0.1, 0.1, 0.2, 0.05, 0.1, 0.15, 0.18], inf),
	\dur, Pseq([1/4, 1/8, 1/8, 1/4, 1/4, 1/2, 1/8, 1/8, 1/8, 1/8], inf),
	\out, ~effectsBus
).play(tc)
)