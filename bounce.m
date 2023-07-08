1;

pkg load signal;

function X = record(sec, samplingRate)
	file = tempname ();
	file= [file,".wav"];
	
	cmd = sprintf ("rec -c1 -r%d %s trim 0 %d",
	                 samplingRate, file, sec)
	
	system (cmd);
	
	X = audioread(file);
end

function conv = conv(rec, sample);
	conv = fftconv(rec, flip(sample));
end

function [convolution, sample] = sampleFind (secSample, secRec, samplingRate)
	input ("Please hit ENTER and record sample!\n", "s");
	sample = record(secSample, samplingRate);
	
	input ("Please hit ENTER and record!\n", "s");
	recording = record(secRec, samplingRate);
	
	convolution = conv(recording, sample);
end

function ls = samplesToSeconds (rec, samplingRate)
	l = length(rec);
	ls = linspace(0,l/samplingRate,l);
end	

function tpks = bounceTimes (convedRecording, samplingRate, minSound)
	tBetweenBounces = 0.1 # min this many sec apart;
	samplesBetweenBounces = tBetweenBounces * samplingRate;

	l = length(convedRecording);
	ls = linspace(0,l/samplingRate,l);

	[pks, ids] = findpeaks(convedRecording,"DoubleSided","MinPeakHeight",minSound,"MinPeakDistance",samplesBetweenBounces);

	tpks = ls(ids);
end

function t = getFirstBounce (tpks, tBounce)
	t1 = tpks(1) + tBounce/2;
	t2 = tpks(2) - tBounce/2;

	t = t2 - t1;
end

function h = heightFromTime (t)
	g = 9.81;

	h = t^2 / 8 * g;
end

function sample = pruneSample(samplingRate)

	input("Press enter to record bounce sample", "s");

	sampleRaw = record(1, samplingRate)

	plot(sampleRaw);

	# Prune sample

	bounds = input("Input beginning and end of sample, as integers:\n");

	sample = sampleRaw(bounds(1):bounds(2),:);

end

function [t, h] = performExperiment (samplingRate, n, sample, minSound, tBounce)
	if (exist("sample", "var") == 0)
		sample = [];
	endif

	if (exist("tBounce", "var") == 0)
		tBounce = 0;
	endif

	if (isempty(sample))
		# record sample
		pruneSample(samplingRate)
	endif

	redoTest = 1;
	if (exist("minSound", "var") == 1)
		redoTestIn = input ("Woud you like to re-record a test run to determine minSound again?");
		redoTest = any (['y','Y'] == redoTestIn(1));
	endif

	if (redoTest)
		# perform test run, ask for minSound
		
		input("Press enter to begin test run", "s");

		testRun = record(5, samplingRate);

		testConvolve = conv(testRun, sample);

		detectedBounces = bounceTimes(testConvolve, samplingRate, 10);

		ls = samplesToSeconds (testConvolve, samplingRate);

		plot(ls, testConvolve, detectedBounces, testConvolve(round(detectedBounces*samplingRate)), 'or');

		minSound = input("Find the highest peak that was not a bounce. Input a value above its volume:\n");

		detectedBouncesPruned = bounceTimes(testConvolve, samplingRate, minSound);

		plot(ls, testConvolve, detectedBouncesPruned, testConvolve(round(detectedBouncesPruned*samplingRate)), 'or');

	endif

	t = [];
	h = [];

	for i = 1:n
		
		# record single experiment, set tpks(i), t(i), h(i) to results

		input("Press enter to begin experiment", "s");

		drop = record(5, samplingRate);

		dropConvolve = conv(drop, sample);

		ls = samplesToSeconds (dropConvolve, samplingRate);

		detectedBounces = bounceTimes(dropConvolve, samplingRate, minSound);

		plot(ls, dropConvolve, detectedBounces, dropConvolve(round(detectedBounces*samplingRate)), 'or');

		tpks = detectedBounces;

		t(i) = getFirstBounce(tpks, tBounce)

		h(i) = heightFromTime(t(i))
	
	end
end






