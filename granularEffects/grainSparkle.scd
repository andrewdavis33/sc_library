/* Sparkling Effects through Granular Synthesis
 * By Andrew Davis
 *
 * Designed to create sparkling effects based on an audio
 * input source.
 */

(
SynthDef(\grainSparkles, {
	arg out = 0, rout, dmix = 1, rmix = 0, amp = 0.01, bufnum, start = 0, end = 1, pos = 0,
	atkTime = 0.01, decTime = 0.2, susTime = 10, relTime = 1, susLvl = 0.4, c1 = (-1), c2 = 1;
	var sig, trig, env, duration;

	duration = atkTime + decTime + susTime + relTime;


	trig = Impulse.kr(10);
	sig = {
		var octaves = Drand([2, 3, 4], inf);
		BufGrain.ar(
			trigger: Dust.kr(60),
			dur: LFNoise0.kr(10).range(0.3, 0.5),
			sndbuf: bufnum,
			rate: Demand.kr(trig, 0, octaves),
			pos: Line.kr(start, end, duration, doneAction: 2),
			interp: 2,
			mul: 2,
			add: 0
		)
	} ! 2;

	// Remove low frequencies for sparkle
	sig = HPF.ar(sig, 1000);

	// Envelope of time duration
	env = EnvGen.kr(
		Env(
			[0, amp, amp * susLvl, amp * susLvl, 0],
			[atkTime, decTime, susTime, relTime],
			[c1, 'lin', 'lin', c2]
		)
	);

	// Pan
	sig = Balance2.ar(sig[0], sig[1], pos);
	sig = sig * env;
	Out.ar(out, sig * dmix);
	Out.ar(rout, sig * rmix);
}).add;
)