/* Channel Vocoder
 * By Andrew Davis
 *
 * Implementation using a bank of bandpass filters to determine the harmonic spectrum of
 * the modulator by tracking the amplitude of the modulator as it passes through each
 * fitler and then use the another bank to modulate the carrier based on the amplitude of
 * each band.
 */

// Would like to try the filter bank implementation from http://www.panix.com/~jens/pvoc-dolson.par
// using a low-pass filter and phase unwrapping

(
SynthDef(\vocoder, {
	arg out = 0, modulatorIn, carrierIn, amp, lowestFreq = 300, highestFreq = 8000, q = 50,
	filterScale = 10, ampBoost = 10.0;
	var numFilters = 41, sig, car, mod, lowAmp, highAmp;

	mod = In.ar(modulatorIn, 2);
	car = In.ar(carrierIn, 2);
	sig = 0;

	// Create a bank of bandpass filters
	numFilters.do({
		arg filterNum;
		var deltaFreq, centerFreq, modAmp, ratio;

		// Find the ratio of the center frequencies between each bandpass filter.
		// Need to subtract by one so that we include both the lowest and highest frequencies
		ratio = (highestFreq/lowestFreq) ** (1/(numFilters - 1));

		// The center frequency of the current BPF
		centerFreq = (ratio ** filterNum) * lowestFreq;

		// Isolate the band from the modulator signal and determine how strong that frequency
		// range is in the modulator signal.  modAmp will be a value between 0 and 1 that represents
		// the peak amplitude.  I've used a limiter here to prevent any particular BPF from sticking
		// out too dramatically.  If one of the partials in the carrier aligns very close to the
		// center frequency it is going to pop out... and not in a good way.
		modAmp = Limiter.ar(Amplitude.ar(BPF.ar(mod, centerFreq, 1/q)), 0.01);

		// Use modAmp to scale the strength of a bandpass filter on the carrier
		// BPF make the sound softer so multiply by some scale to increase the strength.
		sig = sig + BPF.ar(car, centerFreq, 1/q, modAmp * filterScale);
	});

	// Add in some low end using same technique with lowpass filter
	lowAmp = Amplitude.ar(LPF.ar(mod, 200));
	sig = sig + LPF.ar(car, lowestFreq, lowAmp * filterScale/ 8);

	// Add in some high end using same technique with highpass filter
	highAmp = Limiter.ar(Amplitude.ar(HPF.ar(mod, highestFreq)), 0.01);
	sig = sig + HPF.ar(car, 9000, highAmp * filterScale / 8);

	Out.ar(out, sig * ampBoost);
}).add;
)

// Testing

// Modulator - a playback synthdef for speech
(
SynthDef(\play, {
	arg out = 0, amp = 1, bufnum;
	Out.ar(out, PlayBuf.ar(2, bufnum, loop: 1) * amp);
}).add;
)

// Carrier - a C minor seventh chord made of sawtooth waves
(
SynthDef(\saws, {
	arg out = 0, offset = 0;
	var sig = 0;
	var chord = [60, 63, 67, 70] + offset;
	chord.do({
		arg note;
		sig = sig + Saw.ar(note.midicps * (1.0.rrand(1.01)), 0.1) +
		Saw.ar(note.midicps * (1.0.rrand(1.01)), 0.1) + Saw.ar(note.midicps * (1.0.rrand(1.01)), 0.1);
	});
	Out.ar(out, sig ! 2);
}).add;
)

// Load up a speech file
(
var path = thisProcess.nowExecutingPath.dirname.dirname +/+ "sounds" +/+ "makeMoreSounds.aiff";
~buf = Buffer.read(s, path);
)

// Test to make sure synths work
Synth(\play, [\bufnum, ~buf])
Synth(\saws)
s.meter;

// Play the vocoder
(
var carIn = Bus.audio(s, 2);
var modIn = Bus.audio(s, 2);
~play = Synth(\play, [\bufnum, ~buf, \out, modIn]);
~saws = Synth(\saws, [\out, carIn], ~play, \addAfter);
~vocoder = Synth(\vocoder, [\modulatorIn, modIn, \carrierIn, carIn, \q, 100, \filterScale, 30], ~saws, \addAfter);
)

// Change the transposition of the chord
~saws.set(\offset, -12)

FreqScope.new