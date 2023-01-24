/* Amplitude Modulation on Audio Files
 * By Andrew Davis
 *
 * Designed for looping, stereo audio files
 * Demo is a guitar strumming
 */

// Read in an audio file into a buffer that loops
(
var fileName = "guitar.wav"; // Change to whatever you like to test
var path = thisProcess.nowExecutingPath.dirname.dirname +/+ "sounds" +/+ fileName;
s.waitForBoot({
	~buf = Buffer.read(s, path);
});
)

(
SynthDef(\am, {
	arg out = 0, bufnum, amp = 0.2, freq_m = 0.1, mix = 0.2;
	var sig, mod;
	sig = PlayBuf.ar(2, bufnum, loop: 1);
	mod = SinOsc.kr(freq_m);
	sig = XFade2.ar(sig, sig * mod, mix * 2 - 1, amp);
	Out.ar(out, sig);
}).add;
)

x = Synth(\am, [\bufnum, ~buf]);
x.set(\mix, 0.2); // Control the amount of amplitude modulation on a scale of 0 to 1
x.set(\freq_m, 1); // Set frequency of the modulator