/* Bass Pluck
 * By Andrew Davis
 *
 * A simple bass pluck emulation using a triangle wave as
 * the sound source and a Moog filter emulation.
 */


(
SynthDef(\bassPluck, {
	arg out = 0, freq = 100, pos = 0,
	amp = 0.4, atkTime = 0.01, relTime = 0.1, cutoff = 400;
	var sig, env;

	sig = LFTri.ar(freq);
	sig = MoogVCF.ar(sig, cutoff, 0.15);
	env = EnvGen.kr(
		Env.perc(atkTime, relTime, amp),
		doneAction: 2
	) * 2;
	sig = sig * env;
	sig = Pan2.ar(sig, pos);
	Out.ar(out, sig);
}).add;
)

// Play the synth
Synth(\bassPluck, [\freq, 100, \amp, 0.8, \relTime, 0.6])