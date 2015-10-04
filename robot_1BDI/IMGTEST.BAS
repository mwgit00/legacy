' IMAGE PROCESSING TEST ROUTINES
' FOR USE WITH RAMCAM.EXE


sub imgproctest()

	dim bchar as byte
	dim bflag As Boolean
	dim i as byte

	

	call OpenSerialPort(1,19200)		' we are in test mode
	call beep(8,587)

	cmode=0					' start in normal color mode
	call initcolormode()

	do

		do
			call GetByte(bchar,bflag)
		loop while (bflag=False)

		if (bchar=65) then			' A --> Acquire Normal

			call beep(1,329)
			if (cmode<>0) then
				cmode=0
				call initcolormode()
			end if

			call blinkgreen()
			call acquire()
			call blinkred()

			call blinkgreen()
			call imagedump()
			call blinkred()

		end if

		if (bchar=66) then			' B --> Acquire Fire

			call beep(2,329)
			if (cmode<>1) then
				cmode=1
				call initflamemode()
			end if

			call blinkgreen()
			call acquire()
			call blinkred()

			call blinkgreen()
			call imagedump()
			call blinkred()

		end if


		if (bchar=67) then			' C --> Candle Seek

			call beep(3,329)
			if (cmode<>1) then
				cmode=1
				call initflamemode()
			end if

			call blinkgreen()
			call findcandle(glc_y1,glc_y2)
			call PutByte(CByte(gl_candlex))
			call PutByte(0)
			call PutByte(CByte(gl_candler))
			call blinkred()

		end if

		if (bchar=68) then			' D --> Candle Track

			call beep(4,329)
			if (cmode<>1) then
				cmode=1
				call initflamemode()
			end if

			call blinkgreen()
			call blinkgreen()
			call blinkred()
			call blinkred()

			gl_dyn_y1=glc_y1
			gl_dyn_y2=glc_y2

			' run for about 25 seconds

			for i=1 to 100
				call findcandle(gl_dyn_y1,gl_dyn_y2)

				if (gl_candlex > 41) then
					call PutPin(RedLED,LEDoff)
					call PutPin(GreenLED,LEDon)
				elseif (gl_candlex < 39) then
					call PutPin(RedLED,LEDon)
					call PutPin(GreenLED,LEDoff)
				else
					call PutPin(RedLED,LEDon)
					call PutPin(GreenLED,LEDon)
				end if
			next
			call PutPin(RedLED,LEDoff)
			call PutPin(GreenLED,LEDoff)

		end if

		if (bchar=69) then			' E --> receive PR data
			call beep(5,329)
			call PutPin(GreenLED,LEDon)
			call rxColorData()
			call PutPin(GreenLED,LEDoff)
		end if

		if (bchar=70) then			' F --> find wall

			call beep(6,329)
			if (cmode<>0) then
				cmode=0
				call initcolormode()
			end if

			call blinkgreen()
			call findwall()
			call PutByte(CByte(gl_wally))
			call PutByte(CByte(gl_wallf\2))
			call blinkred()

		end if

	loop


end sub
