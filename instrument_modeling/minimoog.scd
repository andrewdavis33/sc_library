
(
SynthDef(\minimoog, {
	arg out = 0, amp = 1, gate = 1,
	select1 = 1, select2 = 0, select3 = 0, noiseSelect = 0,
	freq1 = 440, freq2 = 440, freq3 = 440,
	amp1 = 0.1, amp2 = 0.1, amp3 = 0.1, noiseAmp = 0.1,
	vcaAtk = 0.05, vcaDec = 0.2, vcaSusLvl = 0.5, vcaRel = 0.5,
	vcfStartFreq = 1000, vcfPeakFreq = 3000, vcfEndFreq = 1000, vcfAtk = 0.5, vcfRel = 0.5,
	modSwitch = 0, lfoFreq = 1;
	var osc1, osc2, osc3, noise, lfo, sig, filterEnv, vcf, ampEnv, vca, mod;

	mod = Select.kr(
		modSwitch,
		[
			DC.ar(0), // no modulation
			SinOsc.kr(lfoFreq),
			WhiteNoise.kr(1)
		]
	);

	osc1 = Select.ar(
		select1,
		[
			DC.ar(0), // No signal
			SinOsc.ar(freq1 + mod, mul: amp1),
			LFTri.ar(freq1 + mod, mul: amp1),
			Saw.ar(freq1 + mod, mul: amp1),
		]
	);

	osc2 = Select.ar(
		select2,
		[
			DC.ar(0), // No signal
			SinOsc.ar(freq2 + mod, mul: amp2),
			LFTri.ar(freq2 + mod, mul: amp2),
			Saw.ar(freq2 + mod, mul: amp2),
		]
	);

	osc3 = Select.ar(
		select3,
		[
			DC.ar(0), // No signal
			SinOsc.ar(freq3 + mod, mul: amp3),
			LFTri.ar(freq3 + mod, mul: amp3),
			Saw.ar(freq3 + mod, mul: amp3),
		]
	);

	noise = Select.ar(
		noiseSelect,
		[
			DC.ar(0), // No signal
			WhiteNoise.ar(noiseAmp),
			PinkNoise.ar(noiseAmp),
		]
	);

	sig = Mix.ar([osc1, osc2, osc3, noise]);

	filterEnv = EnvGen.kr(Env([vcfStartFreq, vcfPeakFreq, vcfEndFreq], [vcfAtk, vcfRel]));
	vcf = MoogFF.ar(sig, filterEnv, 1, 0);

	ampEnv = EnvGen.kr(Env.adsr(vcaAtk, vcaDec, vcaSusLvl, vcaRel, amp), gate, doneAction: 2);
	vca = vcf * ampEnv;

	Out.ar(out, vca ! 2);
}).add;
)

(
x = Synth(\minimoog, [
	\amp, 1,

	\select1, 3,
	\freq1, 30,
	\amp1, 0.2,

	\select2, 3,
	\freq2, 60,
	\amp2, 0.4,

	\select3, 0,
	\freq3, 440,
	\amp3, 0,

	\noiseSelect, 2,
	\noiseAmp, 0.05,

	\modSwitch, 0,
	\lfoFreq, 0.1,

	\vcfStartFreq, 1000,
	\vcfPeakFreq, 3000,
	\vcfRelFreq, 1000,
	\vcfAtk, 1,
	\vcfEnd, 1,

	\vcaAtk, 0.01,
	\vcaDec, 0.3,
	\vcaSusLvl, 0.5,
	\vcaRel, 0.5

]);
)

x.set(\gate, 0);

// With keyboard
MIDIClient.init;
MIDIIn.connectAll;
s.meter;

(
~notesDict = Dictionary.new;
~soundDef = \minimoog; // allows for flexibility to choose any synth sound to play

MIDIdef.noteOn(\adsrOn, {
	|vel, num, chan, src|
	var amp = vel.linlin(1, 127, 0, 1);
	var freq = num.midicps;
	var synth = Synth(~soundDef, [
		\amp, 1,

		\select1, 2,
		\freq1, freq/2,
		\amp1, 0.2,

		\select2, 2,
		\freq2, freq,
		\amp2, 0.4,

		\select3, 0,
		\freq3, freq,
		\amp3, 0,

		\noiseSelect, 0,
		\noiseAmp, 0.05,

		\modSwitch, 0,
		\lfoFreq, 0.1,

		\vcfStartFreq, 700,
		\vcfPeakFreq, 700,
		\vcfRelFreq, 700,
		\vcfAtk, 0.05,
		\vcfEnd, 0.05,

		\vcaAtk, 0.01,
		\vcaDec, 0.3,
		\vcaSusLvl, 0.5,
		\vcaRel, 0.5,

		\out, ~reverbBus
	]);
	vel.postln;
	~notesDict.put(num, synth);
});

MIDIdef.noteOff(\adsrOff, {
	|vel, num, chan, src|
	var synth = ~notesDict.at(num);
	synth.set(\gate, 0);
	~notesDict.removeAt(num);
});
)

FreqScope.new;