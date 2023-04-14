s.reboot;

// Main window
(

var wRect;
var wColor;
f = Font ("Kreon", 12);
wRect = Rect(left: 650, top: 150, width: 600, height: 600);
w = Window("Distorsion", wRect, false);
wColor = Color.new255(red: 251, green: 236, blue: 136, alpha: 255);
w.background = wColor;
w.front;
w.alwaysOnTop = true;
~effectName = StaticText(w,Rect(150, 15, 300, 50))
.string_("DISTEACHER")
.align_(\center)
.font_(Font("Kreon", 40));

)

(

~inputBus = Bus.audio(s);
~outputBus = Bus.audio(s);
~xyBus = Bus.audio(s);
~myBuffer = Buffer.alloc(s, 1024, 1);
// ~inputSignal = SinOsc.ar(220, mul:1);
// ~outputSignal = Signal.new;

)


(
~mySynth = SynthDef(\scopes,{

	// var inputSignal, outputSignal;
	// var outputSignal;
	// var inputBus, outputBus;
	var tf;

	var gain, thr;

	gain = 2;
	thr = 0.4;


	~inputSignal = SinOsc.ar(220, mul:1);

	//********************************************************
	// Transfer functions
	//********************************************************

	// tanh behaviour
	/*
	~myPlot = {
		var a;
		a = Line.ar(-3, 3, 0.01);
		a.tanh
	}.plot

	~outputSignal = (gain * ~inputSignal).tanh;
	*/

	// Quadratic
	//***************************************************************
	// Link to the GeoGebra site: https://www.geogebra.org/m/x5bhsngv
	//***************************************************************

	// myBuffer = Buffer.alloc(s, 1024, 1);

	tf = Signal.newClear(513);
	tf.waveFill({arg x, old, i; 2*x-1}); // 0 < x_axis < 513    -1 < y_axis < 1
	tf.waveFill({arg x, old, i;  //    0 < x < 1    -1 < old < 1    0 < i < 512
		if((old>0),
			{// positive
				if((old<(thr/gain)),
					{// linear
						// ("linear pos"+"i ="+i).postln;
						old*gain
					},
					{if((old<((2-thr)/gain)),
						{// quatratic
							// ("quadratic pos"+"i ="+i).postln;
							((((old-((2-thr)/gain)).squared)*gain*gain)/(4*(thr-1)))+1
						},
						{// clip
							// ("clip pos"+"i ="+i).postln;
							1
					})
				})
			},
			{// negative
				if((old>((-1)*thr/gain)),
					{// linear
						// ("linear neg"+"i ="+i).postln;
						old*gain
					},
					{if((old>((thr-2)/gain)),
						{// quatratic
							// ("quadratic neg"+"i ="+i).postln;
							((((old-((thr-2)/gain)).squared)*gain*gain)/(4*(1-thr)))-1
						},
						{// clip
							// ("clip neg"+"i ="+i).postln;
							-1
					})
				})
			}
		)
	});

	// tf.plot;

	~myBuffer.sendCollection(tf.asWavetableNoWrap);

	// ~myBuffer.plot;

	~outputSignal = Shaper.ar(~myBuffer, ~inputSignal, 1, 0);

	//********************************************************
	Out.ar(~inputBus, ~inputSignal);
	Out.ar(~outputBus, ~outputSignal);
	Out.ar(~xyBus, [~inputSignal, ~outputSignal]);

}).play(s, addAction: \addToTail);
)


// Wave scopes
(

// For the following code I followed this example: https://subscription.packtpub.com/book/application-development/9781783289677/1/ch01lvl1sec09/scoping-signals and this updated version: https://gist.github.com/gusano/e961e0ce67b09fea80e9

// create two buffer in order to plot with ScopeOut2 and ScopeView.
~inputBuffer = Buffer.alloc(s, 1024);
~outputBuffer = Buffer.alloc(s, 1024);
~xyBuffer = Buffer.alloc(s, 1024, 2);
~sound = { //trial sound
	~inputSignal = SinOsc.ar(10, mul:1);
	~outputSignal = Shaper.ar(~myBuffer, ~inputSignal, 1, 0);
    ScopeOut2.ar(~inputSignal, ~inputBuffer); // update first buffer
    ScopeOut2.ar(~outputSignal, ~outputBuffer); // update second buffer
	ScopeOut2.ar([~inputSignal, ~outputSignal], ~xyBuffer); // update second buffer
  }.play;

//By using ScopeView, we need to use buffers and ScopeOut2 -> see ScopeView examples in the search section.
~inputScope = ScopeView(w,Rect(40,400,180,176)).server = s;
~inputScope.bufnum = ~inputBuffer.bufnum;
~inputScope.start;
~xyScope = ScopeView(w,Rect(222,400,156,176)).server = s;
~xyScope.bufnum = ~xyBuffer.bufnum;
~xyScope.style = 2;
~xyScope.start;
~outputScope = ScopeView(w,Rect(380,400,180,176)).server = s;
~outputScope.bufnum = ~outputBuffer.bufnum;
~outputScope.start;

~inputScopeName = StaticText(w,Rect(60, 535, 140, 100))
.string_("Clean waveform")
.align_(\center)
.font_(Font("Kreon", 12));
~xyScopeName = StaticText(w,Rect(230, 535, 140, 100))
.string_("Transfer function")
.align_(\center)
.font_(Font("Kreon", 12));
~outputScopeName = StaticText(w,Rect(400, 535, 140, 100))
.string_("Distorted waveform")
.align_(\center)
.font_(Font("Kreon", 12));

/*
inputFreqScope = FreqScopeView(w, Rect(0, 300, 370, 200));
outputFreqScope = FreqScopeView(w, Rect(370, 300, 370, 200));
inputFreqScope.active_(true);
outputFreqScope.active_(true);
inputFreqScope.freqMode_(1);
outputFreqScope.freqMode_(1);
inputFreqScope.inBus_(~inputBus);
outputFreqScope.inBus_(~outputBus);
*/

w.onClose = {(
	~sound.stop;
	~inputBuffer.free;
	~outputBuffer.free;
	~xyBuffer.free;
	~inputScope.stop;
	~outputScope.stop;
	~xyScope.stop;
)};

)


// Knobs
(

var k1_input_level;
var k2_tone;
var k3_disType;
var k4_output_level;
o = ControlSpec.new(minval: 0.0, maxval: 10.0);
i = ControlSpec.new(minval: 0.0, maxval: 10.0);
t = ControlSpec.new(minval: 0.0, maxval: 1.0);
p = ControlSpec.new(minval: 0.0, maxval: 1.0);
k1_input_level = EZKnob(w, Rect(100,95, 80, 80), "Input", i, layout: 'vert2');
k2_tone = EZKnob(w, Rect(210, 95, 80, 80), "Tone", t, layout: 'vert2');
k3_disType = EZKnob(w, Rect(320,95, 80, 80), "Type",  p, layout: 'vert2');
k4_output_level = EZKnob(w, Rect(430, 95, 80, 80), "Output", o, layout: 'vert2');
k1_input_level.font = f;
k2_tone.font = f;
k3_disType.font = f;
k4_output_level.font = f;

)

// Styles buttons
(

a = Button(w, Rect(30, 200, 160, 40))
        .states_([
            ["Steve Ray Vaughan
(Overdrive)", Color.white, Color.new255(red: 169, green: 211, blue: 134, alpha: 255)],
            ["Steve Ray Vaughan
(Overdrive)", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
a.font = f;
b = Button(w, Rect(220, 200, 160, 40))
        .states_([
            ["AC/DC
(Distorsion)", Color.white, Color.new255(red: 169, green: 211, blue: 134, alpha: 255)],
            ["AC/DC
(Distorsion)", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
b.font = f;
c = Button(w, Rect(410, 200, 160, 40))
        .states_([
            ["Matt Bellamy
(Fuzz)", Color.white, Color.new255(red: 169, green: 211, blue: 134, alpha: 255)],
            ["Matt Bellamy
(Fuzz)", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
c.font = f;

)

//Pop Up Menu - Distorsion Type
(

m = EZPopUpMenu.new(w, Rect(310, 342, 205, 20), "CURVE TYPE", layout: \horz);
m.addItem(\Quadratic, {"this is item 0". postln});
m.addItem(\Hyperbolic_tangent, {"this is item 1". postln});
m.addItem(\item2, {"this is item 2". postln});
m.addItem(\item4, {"this is item 4". postln});
m.font_(Font("Kreon", 12));

)

//Pop Up Menu - Input choice
(

m = EZPopUpMenu.new(w, Rect(29, 342, 200, 20), "INPUT SOURCE", layout: \horz);
m.addItem(\Soundcard, {"this is item 0". postln});
m.addItem(\Computer_mic, {"this is item 1". postln});
m.addItem(\Guitar_mp3, {"this is item 2". postln});
m.addItem(\Voice_mp3, {"this is item 4". postln});
m.font_(Font("Kreon", 11));

)

// Curve button
(

var curve_button;
curve_button = Button(w, Rect(522, 338, 45, 30))
        .states_([
            ["SHOW ME
THE CURVE", Color.white, Color.new255(red: 169, green: 211, blue: 134, alpha: 255)],
            ["SHOW ME
THE CURVE", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
curve_button.font_(Font("Kreon", 8));

)