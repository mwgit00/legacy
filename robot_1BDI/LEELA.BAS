' BX-24 RAMCAM ROBOT PROJECT
' CODENAME "LEELA"
' DROID DESIGNATION 1-BDI, Mk VII
' MAIN PROGRAM
' CREATED 9-5-2000
'
' 10-04-2000  FIRST IMAGE ACQUISITION AND TRANSMISSION
' 03-09-2001  First BX-24 to BrainStem communication
' 03-31-2001  Added beeper to BX-24 board



'      01234567 Port B (20<-13)
'      ||||||||
' -------------
'    BX-24 CHIP
' #------------
'      ||||||||
'      76543210 Port C (5->12)


public const GreenLED as byte = 26
public const RedLED as byte = 25

public const LEDon as byte = 0
public const LEDoff as byte = 1

public cmode as integer



sub main()

	Dim nn as integer
	Dim bchar as byte
	Dim bflag As Boolean



	' wait for Stem to warm up

	call beep(2,440)
	call initbx()
	call song()		
	call initcamera()



	'Set portC's Data Dir register to all I  (0 = Input, 1 = OutPut)
	'Register.ddrC = &H00
	'Set portA's Data Dir register to all Output  (0 = Input, 1 = OutPut)



	' attempt to communicate with Stem
	' (send magic byte and await reply)

	call Delay(0.2)
	call beep(2,440)
	call OpenSerialPort(1,9600)
	call Delay(0.2)
	bchar=7
	nn=2500
	call PutByte(173)
	call PutByte(0)
	do
		call GetByte(bchar,bflag)
		nn=nn-1
	loop while ((bflag=False) And (nn>0))



	' execute Trinity Program
	' or Image Test Program
	' based on presence of reply (addr, 0)

	if ((bflag=True) And (bchar=2)) then
		do
			call GetByte(bchar,bflag)
		loop while (bflag=False)
		call beep(2,2000)
		call trinity()
	else
		call imgproctest()
	end if


end sub



sub initbx()
	dim ii as byte
	for ii=1 to 4
		call blinkgreen()
		call blinkred()
	next
end sub

sub blinkgreen()
	call PutPin(GreenLED,LEDon)
	call Delay(0.1)
	call PutPin(GreenLED,LEDoff)
	call Delay(0.1)
end sub

sub blinkred()
	call PutPin(RedLED,LEDon)
	call Delay(0.1)
	call PutPin(RedLED,LEDoff)
	call Delay(0.1)
end sub

sub song()
	call Freqout(13,261,522,100)
	call Freqout(13,277,554,100)
	call Freqout(13,293,586,100)
	call Freqout(13,311,622,100)
	call Freqout(13,329,658,100)
end sub

sub beep(ByVal nBeep as byte, ByVal nFreq as integer)
	dim i as byte
	for i=1 to nBeep	
		call Freqout(13,nFreq,nFreq*2,100)
		call Delay(0.05)
	next
end sub
