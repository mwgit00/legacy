'
' TRINITY FIRE-FIGHTING CONTEST LOGIC
'
' 04-01-2001  Created
' 04-16-2001  Abandoned any hope of Expert Mode
' 04-17-2001  Finally got something working

const xlmotor as byte=0
const xrmotor as byte=1

const brGoWHVC as byte=115
const brGoVC as byte=116
const brGoWH as byte=120
const brStopWH as byte=125
const brInit as byte=127

const bNSeek1 as byte=15
const bCSpeed as byte=133		' 135
const bCIDle as byte=132		' 132
const bCWall as byte=75
const bcthr as byte=46		' 9 inches is 0x36, 0x54 is closer
						' 10 inches is 0x2C-0x2E

const rflxWait as single=0.3




sub trinity()

	dim ii as integer
	dim i as byte
	dim foo as integer
	dim brange as byte
	dim brr as byte


	cmode=1				' start in flame mode
	call initflamemode()


	' kick off BrainStem reflexes

	fireReflex(brInit)
	call writepad(6,132)		' slower wall hug
	call writepad(7,135)		' than default
	call writepad(8,144)


	call configdigIO(1,1)		' wait for active low start
	do
	loop while (readdigIO(1)=1)
	call beep(5,2200)


	' wall hug till see first wall
	' then turn left

	fireReflex(brGoWHVC)
	do
		call Delay(0.02)
	loop while (readpad(0)=0)
	call scoot(118,138,0.9)


	' wall hug till see second wall at a distance
	' then turn left and wait for reflex to die

	call writepad(6,133)		' very slow hug
	call writepad(7,134)		' compared to default
	call writepad(8,136)		' to get better reliability

	fireReflex(brGoWH)
	call Delay(5.0)				' ramp inhibit
	do						' that is so hug aligns
		if (readA2D(1)>26) then
			exit do
		end if
		call Delay(0.02)
	loop
	fireReflex(brStopWH)
	call Delay(rflxWait)
	call scoot(118,118,0.4)
	call scoot(118,138,0.9)


	' go into room 1
	' and take reference reading

	call scoot(148,148,2.1)
	call Delay(0.5)
	brr=readIR02()


	' scan for candle
	' if not found then must be
	' pointing out the door

	call scoot(134,122,1.0)	' turn right
	call gomotor(125,131)		' work back to left
	for i=1 to bNSeek1
		if (candlescan()) then
			if (calign()) then
				call gotocandle()
			end if
			call endbad()		' ERROR!!!
		end if
	next
	call fullstop()
	call Delay(0.5)


	' we did not find the candle
	' so try to line up as we entered

	call scoot(134,122,2.0)	' swing right
	call gomotor(131,125)		' slowly work back to right
	do					' till same as entry
		brange=readIR02()
	loop while (brange<brr)
	call fullstop()
	call Delay(0.5)


	' back and and get ready for wall-hug

	call scoot(108,108,2.1)
	call scoot(138,118,0.9)


	' resume hug till wall found

	call writepad(6,132)		' slower wall hug
	call writepad(7,135)		' than default
	call writepad(8,144)

	fireReflex(brGoWHVC)
	do
		call Delay(0.02)
	loop while (readpad(0)=0)
	call scoot(118,138,0.9)

	call song()
	call Delay(1.0)

	call hugandseek()		' hug and seek through rest of house

end sub



sub hugandseek()
	dim i as byte
	dim brange as byte
	do
		fireReflex(brGoWHVC)		' start hug with
		call Delay(rflxWait)		' continuous scan
		do
			if (candlescan()) then
				call endgame()
			end if
			if (readpad(0)=1) then	' check for stoppage
				call scoot(118,138,0.9)
				exit do
			end if
		loop
	loop
end sub



function candlescan() as Boolean
	call beep(1,2800)
	gl_dyn_y1=glc_y1
	gl_dyn_y2=glc_y2
	call findcandle(gl_dyn_y1,gl_dyn_y2)
	if (gl_candler=0) then
		candlescan=false
	else
		candlescan=true
	end if
end function



sub endgame()
	fireReflex(brStopWH)		' we have found it
	do					' wait for VC to kill
		call Delay(0.1)		' all reflexes
	loop while (readpad(0)=0)

	' candle is found after a right-turn
	' typically with overshoot so re-align

	call gomotor(126,130)
	gl_dyn_y1=glc_y1
	gl_dyn_y2=glc_y2
	do
		call findcandle(gl_dyn_y1,gl_dyn_y2)
		if (gl_candlex > 40) then
			call fullstop()
			exit do
		end if
	loop
	call song()
	call gotocandle()
	call endbad()
end sub



function calign() as Boolean
	dim n as byte
	dim bFound as Boolean			' dyn params already seeded
	bFound=false
	do
		call findcandle(gl_dyn_y1,gl_dyn_y2)
		if (gl_candler=0) then
			exit do
		else
			if (gl_candlex > 41) then
				call gomotor(130,126)
			elseif (gl_candlex < 39) then
				call gomotor(126,130)
			else
				call fullstop()
				bFound=true
				exit do
			end if
		end if
	loop
	calign=bFound
end function



sub gotocandle()

	dim i as byte
	dim brange as byte

	gl_dyn_y1=glc_y1		' reset search
	gl_dyn_y2=glc_y2

	call gomotor(bCSpeed,bCSpeed)

	do
		call findcandle(gl_dyn_y1,gl_dyn_y2)
		if (gl_candler=0) then
			call gomotor(bCSpeed,bCSpeed)
		else
			if (gl_candlex > 41) then
				call PutPin(RedLED,LEDoff)
				call PutPin(GreenLED,LEDon)
				call gomotor(bCSpeed,bCIdle)
			elseif (gl_candlex < 39) then
				call PutPin(RedLED,LEDon)
				call PutPin(GreenLED,LEDoff)
				call gomotor(bCIdle,bCSpeed)
			else
				brange=readA2D(1)
				call beepcmp(brange,bcthr)
				if (brange>bcthr) then
					call fullstop()
					exit do
				end if
				call PutPin(RedLED,LEDon)
				call PutPin(GreenLED,LEDon)
				call gomotor(bCSpeed,bCSpeed)
			end if
		end if

	loop
	call extinguish()
end sub



sub extinguish()
	call scoot(118,138,1.8)
	call configdigIO(0,0)
	call gomotor(126,130)
	call digIOwrite(0,1)
	call Delay(8.0)
	call digIOwrite(0,0)
	call fullstop()
	call endgood()
end sub



sub endgood()
	do
		call song()
		call Delay(0.5)
	loop
end sub

sub endbad()
	do
		call beep(2,1500)
		call Delay(0.2)
	loop
end sub


sub gomotor(ByVal blm as byte, ByVal brm as byte)
	bbuff(0)=3
	bbuff(1)=cmdSRV_ABS
	bbuff(2)=xlmotor
	bbuff(3)=blm
	call sendPacket()
	bbuff(0)=3
	bbuff(1)=cmdSRV_ABS
	bbuff(2)=xrmotor
	bbuff(3)=brm
	call sendPacket()
end sub

sub scoot(ByVal blm as byte, ByVal brm as byte, ByVal ftm as single)
	call gomotor(blm,brm)
	call Delay(ftm)
	call gomotor(128,128)
end sub

sub fullstop()
	call gomotor(128,128)
end sub

sub evade()
	call scoot(118,118,1.1)
	call scoot(118,138,0.9)
end sub

sub beepcmp(ByVal b1 as byte, ByVal b2 as byte)
	call beep(1,2000+CInt(b1)*10)
	call beep(1,2000+CInt(b2)*10)
end sub

sub poop(ByVal bb0 as byte)
	dim bb1 as byte
	dim bb2 as byte
	bb1=bb0\16
	bb2=bb0-bb1*16
	call beep(bb1,500)
	call Delay(0.2)
	call beep(bb2,450)
	call Delay(0.6)
end sub

sub scantest()
	do
		if (candlescan()) then
			call beep(1,3000)
		end if
	loop
end sub
