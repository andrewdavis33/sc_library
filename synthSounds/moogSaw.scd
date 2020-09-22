/* Filtered Sawtooth wave using a Moog-emulated lowpass filter
 * Andrew Davis
 *
 * moogSaw is a SynthDef that takes a bank of sawtooth waves and produces
 * the fundamental and an interval above the fundamental as specified by
 * harmonicRatio.  It is currently set to a default of a perfect 5th.  It
 * creates a nice, rich and spacey synth.
 */

(
SynthDef(\moogSaw, {
	arg out = 0, freq = 440, harmonicRatio = 1.5, res = 0.75, amp = 0.1, pos = 0,
	atkTime = 0.02, decTime = 0.1, susLvl = 0.8, relTime = 1, gate = 1,
	dsthi = 8500;

	var sig, env, ffreq, sawBank;
	var numSaws = 6; // Can change for more sawtooth waves if desired

	// Sound source
	sawBank = {
		arg freq;
		var sig = 0;
		numSaws.do({
			// Randomize the frequency slightly for a chorus effect
			sig = sig + LFSaw.ar(freq * Rand(0.99, 1.01), Rand(0, 1), 1/numSaws);
	    });
		sig
	};

	// Create an interval above the fundamental as specified by the
	// variable harmonicRatio
	sig = sawBank.value(freq) + sawBank.value(freq * harmonicRatio);

	// Filter the signal and sweep the filter cutoff frequency
	ffreq = LinExp.kr(
		LFCub.kr(0.1, 0.5*pi),
		srclo: -1,
		srchi: 1,
		dstlo: freq * 2,
		dsthi: dsthi
	);
	sig = MoogLadder.ar(sig, ffreq, res) * 4;

	// Output ADSR envelope
	env = EnvGen.kr(
		Env.adsr(
			atkTime,
			decTime,
			susLvl,
			relTime,
			amp
		),
		gate,
		doneAction: 2
	);
	sig = sig * env;

	// Panning
	sig = Pan2.ar(sig, pos);

	Out.ar(out, sig);
}).add;
)

// Play the synth
x = Synth(\moogSaw, [\freq, 100, \harmonicRatio, 2, \amp, 0.4]);
x.set(\gate, 0);
s.meter;
