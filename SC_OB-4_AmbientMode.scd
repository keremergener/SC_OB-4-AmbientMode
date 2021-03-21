////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Teenage Engineering OB-4 Ambient Mode
// Just run it
//
// by Kerem Ergener
// 12/02/2021, Bangkok
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
(
s.newBusAllocators;
ServerTree.removeAll;
Buffer.freeAll;

s.options.memSize = 8192 * 64;
s.options.numOutputBusChannels = 16;
//Use of Soundflower is recommended for internal sound routing.
s.options.inDevice = "Soundflower (2ch)";
s.options.outDevice = "MacBook Pro Speakers";


~reverbBus = Bus.audio(s, 1);
~recordBus = Bus.audio(s, 1);

~makeNodes = {
	s.bind({
		~fxGroup = Group.new;
		~reverb = Synth(\reverb, [\in, 5], ~fxGroup);
	});
};

s.waitForBoot({

	s.freeAll;
	Buffer.freeAll;
	s.sync;
	SynthDef(\circularBuf, {
		arg in=0, out=10, buf, recording, loop = 0, trig = -1;
		var sig;
		sig = SoundIn.ar(in);
		sig = RecordBuf.ar(sig, buf, run: recording, loop: loop, doneAction: 2);
		Out.ar(out, sig);
	}).add;

	SynthDef(\player, {
		arg in=0, out=5, buf, rate = 1.0, loop = 0;
		var sig;
		sig = PlayBuf.ar(1, buf, rate: 1, loop: loop, doneAction: 2);
		Out.ar(out, sig);
	}).add;

	SynthDef(\reverb, {
		var out = 0, in = 5, sig, wet;
		sig = In.ar(in, 1);
		sig = FreeVerb2.ar(sig, sig, mix:1, room:0.99, damp:0.99);
		sig = JPverb.ar(sig, 10, 0.6, 1.0, 0.8, 0.4);
		sig = GVerb.ar(sig, 100, 4, 0.2, 1, 15, 0);
		sig = Resonz.ar(sig, LFNoise1.kr(0.01).range(800, 2000), LFNoise1.kr(0.1).range(0.001, 0.8));
		sig = sig.softclip;
		sig = Limiter.ar(sig, 1.0);
		Out.ar(out, sig);
	}).add;

	s.sync;

	//1 second Buffer
	~buffer1 = Buffer.alloc(s, 44100 * 1.0, 1);
	//2 second Buffer
	~buffer2 = Buffer.alloc(s, 44100 * 2.0, 1);
	//2.5 second Buffer
	~buffer3 = Buffer.alloc(s, 44100 * 2.5, 1);
	//3 second Buffer
	~buffer4 = Buffer.alloc(s, 44100 * 3.0, 1);

	s.sync;

	ServerTree.add(~makeNodes);
	ServerTree.run;

	s.sync;


	// ~circ=Pdef(\circular,
	// 	Pbind(
	// 		\instrument, \circularBuf,
	// 		\buf, Prand([~buffer1, ~buffer2, ~buffer3, ~buffer4], inf),
	// 		\recording, Prand([0, 1], inf),
	// 		// \recording, 1,
	// 		\out, 10,
	// 		\dur, Pwhite(4.0, 30.0)
	// )).play;


	~startplaying=Pdef(\hadi,
		Pbind(
			\instrument, \player,
			\buf, Prand([~buffer1, ~buffer2, ~buffer3, ~buffer4], inf),
			\out, 5,
			\dur, Pwhite(0.5, 4.0, inf)
	)).play;


	s.meter;

	~circ=Pdef(\circular,
		Pbind(
			\instrument, \circularBuf,
			\buf, Pseq([~buffer1, ~buffer2, ~buffer3, ~buffer4], 1),
			\recording, 1,
			\out, 10,
			\dur, Pseq([4.0, 4.0, 4.0, 4.0], 1),
	));

	~routiner=Routine{inf.do({~circ.play; [30, 40, 50, 60, 70].choose.wait.postln})}.play

})
)
