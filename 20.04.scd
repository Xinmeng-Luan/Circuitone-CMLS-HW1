s.reboot;

(

// General initializations

~outBus = 0;
~inGain = 1.0;
~gain = 1;
~thr = 1;
~outGain = 1.0;
~freq = 100;
~tone = 100;
~rq = 2;
~db = 10;
~analogPos = 0;
~analogNeg = 0;

~guitarBuffer = Buffer.read(s,"C:/Users/Utente/Distorsion/Clean guitar loop_mono.mp3", bufnum: 11);
~bassBuffer = Buffer.read(s,"C:/Users/Utente/Distorsion/Bass_mono.mp3", bufnum: 12);
~voiceBuffer = Buffer.read(s,"C:/Users/Utente/Distorsion/Voice_mono.mp3", bufnum: 13);
~alabamaBuffer = Buffer.read(s, "C:/Users/Utente/Distorsion/Sweet Home Alabama.mp3", bufnum: 14);


SynthDef.new(\guitar, {|sig|
	sig = PlayBuf.ar(1, bufnum: 11);
	Out.ar(0, sig);
}).add;
SynthDef.new(\voice, {|sig|
	sig = PlayBuf.ar(1, bufnum: 13);
	Out.ar(0, sig);
}).add;
SynthDef.new(\bass, {|sig|
	sig = PlayBuf.ar(1, bufnum: 12);
	Out.ar(0, sig);
}).add;
SynthDef.new(\alabama, {|sig|
	sig = PlayBuf.ar(1, bufnum: 14);
	Out.ar(0, sig);
}).add;
SynthDef.new(\sinusoid, {|sig|
	sig = SinOsc.ar(440, 0, 0.3);
	Out.ar(0, sig);
}).add;

~funcs = [
	{~sinusoid = Synth.new(\sinusoid)},
	{~guitar = Synth.new(\guitar)},
	{~voice = Synth.new(\voice)},
	{~bass = Synth.new(\bass)},
	{~alabama = Synth.new(\alabama)},
	{SoundIn.ar(0, 1)}
];



/*
~oscBus = Bus.audio(s);
~micBus = Bus.audio(s);
a = {SinOsc.ar(~freq)}.play(s, ~oscBus);
b = {SoundIn.ar(0, 1)}.play(s, ~micBus);
~oscBus.scope;
~micBus.scope;
*/

~myBuffer = Buffer.alloc(s, 1024, 1);
~tf = Signal.newClear(513);
~myInBuffer = Buffer.alloc(s, 1024, 1);
~inTf = Signal.newClear(513);

// Input selection function

~inputSelectionFunction = {
	if((~inputMenu.value == 0), {
		"Sin".postln;
		SinOsc.ar(~freq);
		// In.ar(~oscBus);
	}, {
		if((~inputMenu.value == 1), {
			"Mic".postln;
			SoundIn.ar(0, 1);
			// In.ar(~micBus);
		}, {
			"Sin*50".postln;
			SinOsc.ar(~freq*100);
		});
	});
};

// Arctangent transfer function??

// Hyperbolic tangent transfer function

~tanhFunction = {
	~inTf.waveFill({arg x, old, i; 2*x-1});
	~inTf = ~inTf * ~inGain;
	~myInBuffer.sendCollection(~inTf.asWavetableNoWrap);
	~gainedInputSignal = Shaper.ar(~myInBuffer, ~inputSelectionFunction.value, 1, 0);
	~tf.waveFill({arg x, old, i; 2*x-1}); // 0 < x_axis < 513    -1 < y_axis < 1
	~tf.waveFill({arg x, old, i;  //    0 < x < 1    -1 < old < 1    0 < i < 512
		if((old>0),
			{// positive
				old*(~gain+~analogPos)
			},
			{// negative
				old*(~gain+~analogNeg)
			}
		)
	});
	// ~tf = ~tf * ~gain;
	~tf = ~tf.tanh;
	~tf = ~tf * ~outGain;
	~myBuffer.sendCollection(~tf.asWavetableNoWrap);
	Shaper.ar(~myBuffer, ~gainedInputSignal, 1, 0);
	// MidEQ.ar(in: Shaper.ar(~myBuffer, ~gainedInputSignal, 1, 0), freq: ~tone, rq: ~rq, db: ~db);
};

// Foldback transfer function

~foldbackFunction = {
	~inTf.waveFill({arg x, old, i; 2*x-1});
	~inTf = ~inTf * ~inGain;
	~myInBuffer.sendCollection(~inTf.asWavetableNoWrap);
	~gainedInputSignal = Shaper.ar(~myInBuffer, ~inputSelectionFunction.value, 1, 0);
	~tf.waveFill({arg x, old, i; 2*x-1}); // 0 < x_axis < 513    -1 < y_axis < 1
	~tf.waveFill({arg x, old, i;  //    0 < x < 1    -1 < old < 1    0 < i < 512
		if((old>0),
			{// positive
				(~gain*(~gain*old).sin)*((-2)*~gain*old).exp
			},
			{// negative
				(~gain*(~gain*old).sin)*(2*~gain*old).exp;
			}
		)
	});
	if((~gain == 0), {~tf = ~tf * 0;}, {});
	~tf = ~tf * ~outGain;
	~myBuffer.sendCollection(~tf.asWavetableNoWrap);
	Shaper.ar(~myBuffer, ~gainedInputSignal, 1, 0);
	// MidEQ.ar(in: Shaper.ar(~myBuffer, ~gainedInputSignal, 1, 0), freq: ~tone, rq: ~rq, db: ~db);
};

// Quadratic transfer function

~quadraticFunction = {
	// Link to the GeoGebra site: https://www.geogebra.org/m/x5bhsngv
	~inTf.waveFill({arg x, old, i; 2*x-1});
	~inTf = ~inTf * ~inGain;
	~myInBuffer.sendCollection(~inTf.asWavetableNoWrap);
	~gainedInputSignal = Shaper.ar(~myInBuffer, ~inputSelectionFunction.value, 1, 0);
	~tf.waveFill({arg x, old, i; 2*x-1}); // 0 < x_axis < 513    -1 < y_axis < 1
	~tf.waveFill({arg x, old, i;  //    0 < x < 1    -1 < old < 1    0 < i < 512
		if((old>0),
			{// positive
				if((old<(~thr/(~gain+~analogPos))),
					{// linear
						old*(~gain+~analogPos)
					},
					{if((old<((2-~thr)/(~gain+~analogPos))),
						{// quatratic
							((((old-((2-~thr)/(~gain+~analogPos))).squared)*(~gain+~analogPos)*(~gain+~analogPos))/(4*(~thr-1)))+1
						},
						{// clip
							1
					})
				})
			},
			{// negative
				if((old>((-1)*~thr/(~gain+~analogNeg))),
					{// linear
						old*(~gain+~analogNeg)
					},
					{if((old>((~thr-2)/(~gain+~analogNeg))),
						{// quatratic
							((((old-((~thr-2)/(~gain+~analogNeg))).squared)*(~gain+~analogNeg)*(~gain+~analogNeg))/(4*(1-~thr)))-1
						},
						{// clip
							-1
					})
				})
			}
		)
	});
	if((~gain == 0), {~tf = ~tf * 0;}, {});
	~tf = ~tf * ~outGain;
	~myBuffer.sendCollection(~tf.asWavetableNoWrap);
	Shaper.ar(~myBuffer, ~gainedInputSignal, 1, 0);
	// MidEQ.ar(in: Shaper.ar(~myBuffer, ~gainedInputSignal, 1, 0), freq: ~tone, rq: ~rq, db: ~db);
};

// Choose a mode - Initial PopUp

f = Font ("Kreon", 12);
~initialPopUp = Window.new("Initial mode choice", Rect(left: 650, top: 150, width: 400, height: 115), false);
~initialPopUp.front;
~initialPopUp.background = ~wColor;
~initialText = StaticText(~initialPopUp, Rect(20, 10, 380, 50));
~initialText.string = "Welcome to DISTEACHER, choose a mode to start.";
~initialText.font = Font("Kreon", 17);
~tutorialButtonStart = Button(~initialPopUp, Rect(50, 70, 100, 30));
~tutorialButtonStart.font = f;
~tutorialButtonStart.states_([
	["Tutorial mode", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)],
	["Tutorial mode", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
]);
~tutorialButtonStart.action_({|butt|
	if (butt.value==1,
		{
			w.front;
			~tutorialw.front;
			~tutorialButton.value = 1;
			~initialPopUp.close;
			~inputMenu.items_(["Sinusoid", "Guitar mp3", "Voice mp3", "Bass mp3", "Sweet Home Alabama"]);
			~playButton = Button(w, ~playButRect)
			           .states_([
				["Play", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)],
				["Pause", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
			])
			.action_({|butt|
				if (butt.value==0,
					{
						//~snd.release;
						CmdPeriod.run;
					},
					{~snd = ~funcs.at(~inputMenu.value).play;}
			)
			});
			~playButton.font_(Font("Kreon", 15));
		},
		{};
		~inputMenu.action = {
			~playButton.value = 0;
			CmdPeriod.run;
		};
)});

~iCanDoItButtonStart = Button(~initialPopUp, Rect(250, 70, 100, 30))
        .states_([
            ["I can do it", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)],
            ["I can do it", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~iCanDoItButtonStart.font = f;
~iCanDoItButtonStart.value = 0;
~iCanDoItButtonStart.action_({|butt|
	if (butt.value==1,
		{w.front; ~iCanDoItButton.value = 1; ~iCanDoItw.front; ~initialPopUp.close; w.background = ~wColor2; ~inputMenu.items_(["Computer mic", "Soundcard"]);},
		{};
)});

// Main window

f = Font ("Kreon", 12);
~wRect = Rect(left: 650, top: 150, width: 600, height: 500);
w = Window("Distorsion", ~wRect, false);
~wColor = Color.new255(red: 251, green: 236, blue: 136, alpha: 255);
~wColor2 = Color.new255(red: 255, green: 165, blue: 0, alpha: 255);
w.background = ~wColor;
w.alwaysOnTop = true;
~effectName = StaticText(w,Rect(150, 15, 300, 50))
.string_("DISTEACHER")
.align_(\center)
.font_(Font("Kreon", 40));

w.onClose = {(
	~sound.stop;
	Buffer.freeAll(s);
	~inputScope.stop;
	~outputScope.stop;
	~xyScope.stop;
	/*
	~oscBus.free;
	~micBus.free;
	a.free;
	b.free;
	*/
)};

// Analog button

~analogButton = Button(w, Rect(500, 63, 70, 30))
        .states_([
            ["Analog", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)],
            ["Analog", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~analogButton.font = f;
~analogButton.action_({|butt|
	// ("analogButton:"+butt.value).postln;
	if ((butt.value==1),
		{
			~analogPos = (1.0.rand.round(0.01)-1.0.rand.round(0.01))*0.1*~gain;
			~analogNeg = (1.0.rand.round(0.01)-1.0.rand.round(0.01))*0.1*~gain;
			~k0_inGain.doAction;
			("AnalogPos from Button:"+~analogPos).postln;
			("AnalogNeg from Button:"+~analogNeg).postln;
		},
		{
			~analogPos = 0;
			~analogNeg = 0;
			~k0_inGain.doAction;
		}
)});

// Knobs

i = ControlSpec.new(minval: 0.0, maxval: 10.0);
g = ControlSpec.new(minval: 0.0, maxval: 10.0);
t = ControlSpec.new(minval: 10, maxval: 22000);
p = ControlSpec.new(minval: 0.0, maxval: 1.0);
o = ControlSpec.new(minval: 0.0, maxval: 2.0);
~k0_inGain = EZKnob(w, Rect(30, 95, 80, 80), "Input gain", i, initVal: 1, layout: 'vert2');
~k1_gain = EZKnob(w, Rect(145,95, 80, 80), "Gain", g, initVal: 1, layout: 'vert2');
~k2_tone = EZKnob(w, Rect(260, 95, 80, 80), "Tone", t, initVal: 100, layout: 'vert2');
~k3_disThr = EZKnob(w, Rect(375,95, 80, 80), "Harshness",  p, initVal: 1, layout: 'vert2');
~k4_output_level = EZKnob(w, Rect(490, 95, 80, 80), "Output", o, initVal: 1, layout: 'vert2');
~k0_inGain.font = f;
~k1_gain.font = f;
~k2_tone.font = f;
~k3_disThr.font = f;
~k4_output_level.font = f;

~k0_inGain.action_({
	arg knob;
	~overdriveButton.value = 0;
	~fuzzButton.value = 0;
	~distorsionButton.value = 0;
	~inGain = knob.value;
	~inTf.waveFill({arg x, old, i; 2*x-1});
	~inTf = ~inTf * ~inGain;
	~myInBuffer.sendCollection(~inTf.asWavetableNoWrap);
	~gainedInputSignal = Shaper.ar(~myInBuffer, ~inputSelectionFunction.value, 1, 0);
	if(((~dystTypeMenu.value == 1)||(~dystTypeMenu.value == 0)), {
		~outputSignal = ~quadraticFunction.value;
		// ~outputSignal = MidEQ.ar(in: ~quadraticFunction.value, freq: ~tone, rq: ~rq, db: ~db);
	}, {
		if((~dystTypeMenu.value == 2), {
			~outputSignal = ~tanhFunction.value;
			// ~outputSignal = MidEQ.ar(in: ~~tanhFunction.value, freq: ~tone, rq: ~rq, db: ~db);
		}, {
			~outputSignal = ~foldbackFunction.value;
		});
	});
});

~k1_gain.action_({
	arg knob;
	~overdriveButton.value = 0;
	~fuzzButton.value = 0;
	~distorsionButton.value = 0;
	~gain = knob.value;
	if(((~dystTypeMenu.value == 1)||(~dystTypeMenu.value == 0)), {
		~outputSignal = ~quadraticFunction.value;
		// ~outputSignal = MidEQ.ar(in: ~quadraticFunction.value, freq: ~tone, rq: ~rq, db: ~db);
	}, {
		if((~dystTypeMenu.value == 2), {
			~outputSignal = ~tanhFunction.value;
			// ~outputSignal = MidEQ.ar(in: ~~tanhFunction.value, freq: ~tone, rq: ~rq, db: ~db);
		}, {
			~outputSignal = ~foldbackFunction.value;
		});
	});
});

~k2_tone.action_({
	arg knob;
	~overdriveButton.value = 0;
	~fuzzButton.value = 0;
	~distorsionButton.value = 0;
	~tone = knob.value;
	if(((~dystTypeMenu.value == 1)||(~dystTypeMenu.value == 0)), {
		~outputSignal = ~quadraticFunction.value;
		// ~outputSignal = MidEQ.ar(in: ~quadraticFunction.value, freq: ~tone, rq: ~rq, db: ~db);
	}, {
		if((~dystTypeMenu.value == 2), {
			~outputSignal = ~tanhFunction.value;
			// ~outputSignal = MidEQ.ar(in: ~~tanhFunction.value, freq: ~tone, rq: ~rq, db: ~db);
		}, {
			~outputSignal = ~foldbackFunction.value;
		});
	});
});

~k3_disThr.action_({
	arg knob;
	~overdriveButton.value = 0;
	~fuzzButton.value = 0;
	~distorsionButton.value = 0;
	if((~dystTypeMenu.value == 1), {~thr = knob.value;}, {
		if(((~dystTypeMenu.value == 0)||(~dystTypeMenu.value == 2)), {knob.value = 1; ~thr = 1;}, {});
	});
	if(((~dystTypeMenu.value == 1)||(~dystTypeMenu.value == 0)), {
		~outputSignal = ~quadraticFunction.value;
		// ~outputSignal = MidEQ.ar(in: ~quadraticFunction.value, freq: ~tone, rq: ~rq, db: ~db);
	}, {
		if((~dystTypeMenu.value == 2), {
			~outputSignal = ~tanhFunction.value;
			// ~outputSignal = MidEQ.ar(in: ~~tanhFunction.value, freq: ~tone, rq: ~rq, db: ~db);
		}, {
			~outputSignal = ~foldbackFunction.value;
		});
	});
});

~k4_output_level.action_({
	arg knob;
	~overdriveButton.value = 0;
	~fuzzButton.value = 0;
	~distorsionButton.value = 0;
	~outGain = knob.value;
	if(((~dystTypeMenu.value == 1)||(~dystTypeMenu.value == 0)), {
		~outputSignal = ~quadraticFunction.value;
		// ~outputSignal = MidEQ.ar(in: ~quadraticFunction.value, freq: ~tone, rq: ~rq, db: ~db);
	}, {
		if((~dystTypeMenu.value == 2), {
			~outputSignal = ~tanhFunction.value;
			// ~outputSignal = MidEQ.ar(in: ~~tanhFunction.value, freq: ~tone, rq: ~rq, db: ~db);
		}, {
			~outputSignal = ~foldbackFunction.value;
		});
	});
});

// Styles buttons

~overdriveButton = Button(w, Rect(30, 200, 160, 40))
        .states_([
            ["Steve Ray Vaughan
(Overdrive)", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)],
            ["Steve Ray Vaughan
(Overdrive)", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~overdriveButton.font = f;

~distorsionButton = Button(w, Rect(220, 200, 160, 40))
        .states_([
            ["AC/DC
(Distorsion)", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)],
            ["AC/DC
(Distorsion)", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~distorsionButton.font = f;

~fuzzButton = Button(w, Rect(410, 200, 160, 40))
        .states_([
            ["Matt Bellamy
(Fuzz)", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)],
            ["Matt Bellamy
(Fuzz)", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~fuzzButton.font = f;

~overdriveButton.action_({|me|
	if (me.value == 1,
		{
			~k1_gain.value = 2; ~k2_tone.value = 500; ~k3_disThr.value = 0.3; ~k4_output_level.value = 0.8; ~distorsionButton.value = 0; ~fuzzButton.value = 0;
			~gain = ~k1_gain.value; ~thr = ~k3_disThr.value; ~outGain = ~k4_output_level.value;
			~dystTypeMenu.value = 1;
			if(((~dystTypeMenu.value == 1)||(~dystTypeMenu.value == 0)), {
				~outputSignal = ~quadraticFunction.value;
				// ~outputSignal = MidEQ.ar(in: ~quadraticFunction.value, freq: ~tone, rq: ~rq, db: ~db);
			}, {
				if((~dystTypeMenu.value == 2), {
					~outputSignal = ~tanhFunction.value;
					// ~outputSignal = MidEQ.ar(in: ~~tanhFunction.value, freq: ~tone, rq: ~rq, db: ~db);
				}, {
					~outputSignal = ~foldbackFunction.value;
				});
			});
		};
)});

~distorsionButton.action_({|me|
	if (me.value == 1,
		{
			~k1_gain.value = 7; ~k2_tone.value = 1000; ~k3_disThr.value = 0; ~k4_output_level.value = 0.8; ~overdriveButton.value = 0; ~fuzzButton.value = 0;
			~gain = ~k1_gain.value; ~thr = ~k3_disThr.value; ~outGain = ~k4_output_level.value;
			~dystTypeMenu.value = 1;
			if(((~dystTypeMenu.value == 1)||(~dystTypeMenu.value == 0)), {
				~outputSignal = ~quadraticFunction.value;
				// ~outputSignal = MidEQ.ar(in: ~quadraticFunction.value, freq: ~tone, rq: ~rq, db: ~db);
			}, {
				if((~dystTypeMenu.value == 2), {
					~outputSignal = ~tanhFunction.value;
					// ~outputSignal = MidEQ.ar(in: ~~tanhFunction.value, freq: ~tone, rq: ~rq, db: ~db);
				}, {
					~outputSignal = ~foldbackFunction.value;
				});
			});
		};
)});

~fuzzButton.action_({|me|
	if (me.value == 1,
		{
			~k1_gain.value = 9; ~k2_tone.value = 15000; ~k3_disThr.value = 0.8; ~k4_output_level.value = 0.5; ~overdriveButton.value = 0; ~distorsionButton.value = 0;
			~gain = ~k1_gain.value; ~thr = ~k3_disThr.value; ~outGain = ~k4_output_level.value;
			~dystTypeMenu.value = 1;
			if(((~dystTypeMenu.value == 1)||(~dystTypeMenu.value == 0)), {
				~outputSignal = ~quadraticFunction.value;
				// ~outputSignal = MidEQ.ar(in: ~quadraticFunction.value, freq: ~tone, rq: ~rq, db: ~db);
			}, {
				if((~dystTypeMenu.value == 2), {
					~outputSignal = ~tanhFunction.value;
					// ~outputSignal = MidEQ.ar(in: ~~tanhFunction.value, freq: ~tone, rq: ~rq, db: ~db);
				}, {
					~outputSignal = ~foldbackFunction.value;
				});
			});
		};
)});

//Pop Up Menu - Distorsion Type

~dystTypeMenu = EZPopUpMenu.new(w, Rect(366, 260, 205, 20), "CURVE TYPE", layout: \horz);
~dystTypeMenu.addItem(\Linear, {"Linear".postln; ~k3_disThr.doAction;});
~dystTypeMenu.addItem(\Quadratic, {"Quadratic".postln; ~k3_disThr.doAction;});
~dystTypeMenu.addItem(\Hyperbolic_tangent, {"Hyperbolic tangent".postln; ~k3_disThr.doAction;});
~dystTypeMenu.addItem(\Foldback, {"Foldback".postln; ~k3_disThr.doAction;});
~dystTypeMenu.font_(Font("Kreon", 12));

//Pop Up Menu - Input choice

~inputMenuTitle = StaticText(w, Rect(32, 260, 90, 20))
	.string = "INPUT SOURCE";
~inputMenuTitle.font_(Font("Kreon", 11));
~inputMenu = PopUpMenu.new(w, Rect(118, 260, 100, 20));
~inputMenu.font_(Font("Kreon", 11));

// Wave scopes

// For the following code I followed this example: https://subscription.packtpub.com/book/application-development/9781783289677/1/ch01lvl1sec09/scoping-signals and this updated version: https://gist.github.com/gusano/e961e0ce67b09fea80e9

// create two buffer in order to plot with ScopeOut2 and ScopeView.
~inputBuffer = Buffer.alloc(s, 1024);
~outputBuffer = Buffer.alloc(s, 1024);
~xyBuffer = Buffer.alloc(s, 1024, 2);
~sound = {
	~input = ~inputSelectionFunction.value;
	~gainedInputSignal = Shaper.ar(~myInBuffer, ~input, 1, 0);
	if(((~dystTypeMenu.value == 1)||(~dystTypeMenu.value == 0)), {
		~outputSignal = ~quadraticFunction.value;
		// ~outputSignal = MidEQ.ar(in: ~quadraticFunction.value, freq: ~tone, rq: ~rq, db: ~db);
	}, {
		if((~dystTypeMenu.value == 2), {
			~outputSignal = ~tanhFunction.value;
			// ~outputSignal = MidEQ.ar(in: ~~tanhFunction.value, freq: ~tone, rq: ~rq, db: ~db);
		}, {
			~outputSignal = ~foldbackFunction.value;
		});
	});
	ScopeOut2.ar(~gainedInputSignal, ~inputBuffer); // update input buffer
    ScopeOut2.ar(~outputSignal, ~outputBuffer); // update output buffer
	ScopeOut2.ar([~input, ~outputSignal], ~xyBuffer); // update xy buffer
	Out.ar(~outBus, ~outputSignal);
}.play;

//By using ScopeView, we need to use buffers and ScopeOut2 -> see ScopeView examples in the search section.
~inputScope = ScopeView(w,Rect(30,300,186,176)).server = s;
~inputScope.bufnum = ~inputBuffer.bufnum;
~inputScope.yZoom = 0.9;
~inputScope.start;
~xyScope = ScopeView(w,Rect(222,300,156,176)).server = s;
~xyScope.bufnum = ~xyBuffer.bufnum;
~xyScope.style = 2;
~xyScope.start;
~outputScope = ScopeView(w,Rect(384,300,186,176)).server = s;
~outputScope.bufnum = ~outputBuffer.bufnum;
~outputScope.yZoom = 0.9;
~outputScope.start;

~inputScopeName = StaticText(w,Rect(53, 435, 140, 100))
.string_("Clean waveform")
.align_(\center)
.font_(Font("Kreon", 12));
~xyScopeName = StaticText(w,Rect(230, 435, 140, 100))
.string_("Transfer function")
.align_(\center)
.font_(Font("Kreon", 12));
~outputScopeName = StaticText(w,Rect(407, 435, 140, 100))
.string_("Distorted waveform")
.align_(\center)
.font_(Font("Kreon", 12));

// Mode Buttons
~playButRect = Rect(275, 260, 50, 30);
~tutorialButton = Button(w, Rect(30, 25, 100, 30));
~tutorialButton.states_([
	["Tutorial mode", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)],
	["Tutorial mode", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
]);
~tutorialButton.action_({|butt|
	// butt.value.postln;
	if (butt.value==0,
		{
			w.background = ~wColor2;
			~iCanDoItButton.value = 1;
			~playButton.close;
		},
		{
			w.background = ~wColor;
			~iCanDoItButton.value = 0;
			~tutorialw.front;
			~playButton.close;
			~inputMenu.clear;
			~inputMenu.items_(["Sinusoid", "Guitar mp3", "Voice mp3", "Bass mp3", "Sweet Home Alabama"]);
			~inputMenu.action = {
				~playButton.value = 0;
				CmdPeriod.run;
			};
			~playButton = Button(w, ~playButRect)
			           .states_([
				["Play", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)],
				["Pause", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
			])
			.action_({|butt|
				if (butt.value==0,
					{
						//~snd.release;
						CmdPeriod.run;
					},
					{~snd = ~funcs.at(~inputMenu.value).play;}
			)
			});
			~playButton.font_(Font("Kreon", 15));
		};
)});
~tutorialButton.font = f;
~tutorialw = Window("Tutorial mode", Rect(left: 650, top: 460, width: 600, height: 160), false);
~tutorialw.background = Color.new255(red: 169, green: 211, blue: 134, alpha: 255);
~tutorialw.alwaysOnTop = true;
~tutorialText = StaticText(~tutorialw, Rect(left: 20, top: 0, width: 560, height: 120));
~tutorialText.font_(Font("Kreon", 13));
~tutorialText.string =
"
                                                       TUTORIAL MODE
• Choose one audio file from the 'Input Source' menu.
• Switch between the three distorsion presets and change the parameters as you prefer.
• When you feel comfortable, switch to the 'I can do it' mode and try to distort some of your own sounds! Have fun!";
~gotItButton = Button(~tutorialw, Rect(275, 130, 50, 20));
~gotItButton.states_([
	["Got It"],
	["Got It"],
]);
~gotItButton.action_({|butt|
	// butt.value.postln;
	if (butt.value==1,
		{~tutorialw.close;};
)});

~iCanDoItButton = Button(w, Rect(470, 25, 100, 30))
        .states_([
            ["I can do it", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)],
            ["I can do it", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~iCanDoItButton.font = f;
~iCanDoItButton.value = 0;
~iCanDoItButton.action_({|butt|
	if (butt.value==1,
	{
			w.background = ~wColor2;
			~tutorialButton.value = 0;
			~playButton.close;
			~inputMenu.clear;
			~inputMenu.items_(["Computer mic", "Soundcard"]);
			~iCanDoItw.front;
	},
	{w.background = ~wColor; ~tutorialButton.value = 1};
)});
~iCanDoItw = Window("I can do it mode", Rect(left: 650, top: 460, width: 600, height: 130), false);
~iCanDoItw.background = Color.new255(red: 169, green: 211, blue: 134, alpha: 255);
~iCanDoItw.alwaysOnTop = true;
~tutorialText = StaticText(~iCanDoItw, Rect(left: 20, top: 0, width: 560, height: 80));
~tutorialText.font_(Font("Kreon", 13));
~tutorialText.string =
"
                                                       I CAN DO IT MODE
• Choose one audio input from the 'Input Source' menu.
• Start to play and adjust the parameters to reach the desired sound. Have fun!";
~gotItButton2 = Button(~iCanDoItw, Rect(275, 100, 50, 20));
~gotItButton2.states_([
	["Got It"],
	["Got It"],
]);
~gotItButton2.action_({|butt|
	if (butt.value==1,
		{~iCanDoItw.close;};
)});

// Window "Knob roles"

~knobInfoButton = Button(w, Rect(30, 63, 25, 30))
        .states_([
            ["i", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)],
            ["i", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~knobInfoButton.font = (Font("Kreon", 25));
~knobInfoButton.action_({|butt|
	if (butt.value==1,
		{
			~infow = Window("Knobs roles", Rect(left: 325, top: 500, width: 320, height: 220), false);
			~infow.background = Color.new255(red: 169, green: 211, blue: 134, alpha: 255);
			~infow.alwaysOnTop = true;
			~infos = StaticText(~infow, Rect(left: 10, top: 0, width: 300, height: 190));
			//~infos.allign = \top;
			//~infos.font = Font("Kreon", 9);
			~infos.string =
			"• INPUT KNOB: set the desired input volume.
• GAIN KNOB: this value represent the slope of the linear portion of the transfer function.
• TONE KNOB: set the frequency filter that helps you to shape the desired sound. Set it at a low value if you want a mellower and bassy sound, set it high if you want a richer and full of highs sound.
• HARSNESS KNOB: changes the shape of the quadratic portion of the transfer function. It's linked to the threashold where the linear part ends and the quadratic part starts:
    0 --> only quadratic shape
    1 --> only linear shape (clip)
• OUTPUT KNOB: set the desired output volume.
• ANALOG BUTTON: introduce asymmetrical behaviour in the transfer function, typical of real analogue circuits.";
			~infow.front;
			~gotItButton = Button(~infow, Rect(135, 192, 50, 20));
			~gotItButton.states_([
				["Got It"],
				["Got It"],
			]);
			~gotItButton.action_({|butt|
				if (butt.value==1,
					{~knobInfoButton.value = 0; ~infow.close;};
		)})}
)});

// Lo fa iniziare senza che emetta suono
CmdPeriod.run;

)
