/* A Rising Reverb
 * By Andrew Davis
 *
 * This artificial reverb creates a rising whoosh tail as the audio plays by
 * modulating the delay time.  Great for short snippets of sound.  Currently
 * designed for mono input and produces a stereo output.
 */

// Caution that the reverb can blow-up in terms of gain given certain loud inputs
// Poll output before sending to speakers
(
SynthDef(\risingReverb, {
	arg out = 0, amp = 1, bufnum, dry = 0.7, normWet = 0.5, riseWet = 0.5, gate = 0,
	lpfCutoff = 1600, hold = 0, riseWait = 0;
	var sig, verb, verbRising, delayTimeMod, numFilters = 7;
	sig = PlayBuf.ar(1, bufnum);

	// Normal Reverb
	verb = sig;
	numFilters.do({
		verb = AllpassN.ar(verb, 0.2, {Rand(0.05, 0.06)} ! 2, 0.5)
	});
	sig = (dry * sig) + (normWet * verb);

	// Rising Reverb
	delayTimeMod = {
		var initialDelay = Rand(0.14, 0.16);
		EnvGen.kr(
			envelope: Env(
				[initialDelay, initialDelay, Rand(0.04, 0.06)],
				[hold, Rand(6, 8)] // orig 6, 8
			)
		)
	};
	verbRising = sig;
	numFilters.do({
		verbRising = AllpassC.ar(
			in: verbRising,
			maxdelaytime: 0.2,
			delaytime: delayTimeMod ! 2,
			decaytime: {Rand(3, 4)} ! 2, // originally 3, 4
			mul: 1
		);
	});
	verb = LPF.ar(verbRising, lpfCutoff);
	verb = DelayN.ar(verb, 10, riseWait);
	sig = (dry * sig) + (riseWet * verbRising);
	sig = sig * amp;
	DetectSilence.ar(sig, 0.0001, doneAction: 2);
	Out.ar(out, sig);
}).add;
)

// Demonstrate reverb using an excerpt from a Beethoven symphony
(
var path = thisProcess.nowExecutingPath.dirname.dirname +/+ "sounds" +/+ "beethoven_frag.wav";
~buf = Buffer.read(s, path);
)

// Play excerpt
{PlayBuf.ar(1, ~buf)}.play;

// Play excerpt with reverb
Synth(\risingReverb, [\bufnum, ~buf])