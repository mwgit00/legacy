' Fire-Fighting Image Processing Software
' Created 10-15-2000
'
' 10-15-2000  Candle Found (3 seconds for entire image scan)
' 10-17-2000  Reduced scan time for entire image to < 1 second
' 10-22-2000  Tested early exit after max found -- no big help
' 12-02-2000  Altered Candle Find routine to update globals
' 12-03-2000  Added place-holder benchmark code for tube finding
' 03-13-2001  Updated color stuff (EEPROM data storage)
' 04-07-2001  Added wall find and reworked candle find exposure





public gl_wally as integer			' global wall data
public gl_wallf as integer

public gl_candlex as integer		' global candle data
public gl_candley as integer
public gl_candler as integer

public gl_dyn_y1 as integer		' bounds for search
public gl_dyn_y2 as integer

public const glc_y1 as integer = 643	' 4*160+3
public const glc_y2 as integer = 18563	' 116*160+3
public const glc_dy as integer = 960	' 6*160 (6 rows)
public const glc_dq as integer = 1920	' 12*160 (12 rows)



' inv(C) for target color (9 bytes)
' mean vector for target color (3 bytes)
' 80% 90% 95% 98% thresholds (4 bytes)

dim zz as single
dim aaa(0 to 15) as single

const cvColorDataSize as byte=64		' 9 mat, 3 avg, 4 thr (32 bit)
const cvYellowTube as byte=0		' my special colors
const cvRedBall as byte=1





sub findwall()

	' starting offset bx=4, by=3 gets blue pixels
	' starting offset bx=4, by=4 gets green pixels
	' starting offset bx=3, by=4 gets red pixels
	
	dim addr as integer
	dim addrl as integer
	dim addrh as integer

	dim j as integer
	dim ii as integer
	dim jj as integer
	dim kk as integer

	dim kkmax as integer

	dim cpixg as byte
	dim cpixb as byte

	dim fthr as single
	dim fmax as single
	dim ff as single
	dim a9 as single
	dim a8 as single
	dim a7 as single
	dim a6 as single
	dim a5 as single
	dim a4 as single
	dim a3 as single
	dim a2 as single
	dim a1 as single

	fmax=0.0

	call acquire()
	call outportb(cr_uapg,&H00)

	kkmax=0
	kk=0

	jj=3928				' use row*160+4, step=2*160
						' +4 is offset to green pixel	
						' y=(24 to 118) x=84
						' equiv to 47 iterations

	for j=1 to 47

		addrh=jj\256
		addrl=jj-(addrh*256)
		call outportb(cr_uac1,CByte(addrl))
		call outportb(cr_uac2,CByte(addrh))
		Register.DDRC=&H00

		' read green column (skip blue ) in normal color image

		Register.PortA=bx0100_0100	' low CE and OE
		cpixg=Register.PinC
		Register.PortA=bx0111_0100	' high CE and OE
		Register.PortA=bx0100_0100	' low CE and OE
		cpixb=Register.PinC
		Register.PortA=bx0111_0100	' high CE and OE
			
		a9=a8
		a8=a7
		a7=a6
		a6=a5
		a5=a4
		a4=a3
		a3=a2
		a2=a1
		a1=CSng(cpixg)
		ff=(a1-a9)*(0.050)+(a2-a8)*(0.260)+(a3-a7)*(0.667)+(a4-a6)*(0.736)
		ff=abs(ff)
		if ((kk>9) and (ff>fmax)) then
			fmax=ff
			kkmax=kk
		end if
		
		kk=kk+1
		jj=jj+320

	next

	gl_wally=kkmax
	gl_wallf=CInt(fmax)

end sub





sub findcandle(ByVal y1 as integer, ByVal y2 as integer)
	
	' starting offset bx=4, by=3 gets blue pixels
	' starting offset bx=4, by=4 gets green pixels
	' starting offset bx=3, by=4 gets red pixels
	
	dim addr as integer
	dim addrl as integer
	dim addrh as integer

	dim ii as integer
	dim jj as integer

	dim thr as byte
	dim cpixr as byte
	dim cpixg as byte


	dim nacc1 as integer
	dim naccrun as integer
	dim naccmaxr as integer
	dim naccmaxx as integer
	dim naccmaxy as integer
	dim naccmax1 as integer

	dim bpre as Boolean

	call acquire()

	call outportb(cr_uapg,&H00)
	thr=250

	naccmaxr=0
	naccmaxx=0
	naccmaxy=0
	naccmax1=0

	jj=y1				' use row*160+3, step=6*160
						' +3 is offset to red pixel	

	do while (jj<=y2)

		bpre=false

		addrh=jj\256
		addrl=jj-(addrh*256)
		call outportb(cr_uac1,CByte(addrl))
		call outportb(cr_uac2,CByte(addrh))

		Register.DDRC=&H00

		for ii=3 to 77

			' read red in shuffled image

			Register.PortA=bx0100_0100	' low CE and OE
			cpixr=Register.PinC
			Register.PortA=bx0111_0100	' high CE and OE

			if (cpixr>=thr) then
				if (bpre=false) then
					naccrun=1
				else
					naccrun=naccrun+1
				end if
				if (naccrun>naccmaxr) then
					naccmaxy=jj
					naccmaxr=naccrun
					naccmax1=ii
				end if
				bpre=true
			else
				bpre=false
			end if
		next

		jj=jj+glc_dy

	loop

	naccmaxx=(2*naccmax1-naccmaxr)\2

	gl_candlex=naccmaxx
	gl_candley=naccmaxy
	gl_candler=naccmaxr

	' perform dynamic update of search bounds
	' (limit search to +- 2 rows from last hit)
	' (reset to maximum bounds on a miss)

	if (naccmaxx=0) then
		gl_dyn_y1=glc_y1			' MISS
		gl_dyn_y2=glc_y2
	else
		gl_dyn_y1=naccmaxy-glc_dq	' HIT
		gl_dyn_y2=naccmaxy+glc_dq

		if (gl_dyn_y1 < glc_y1) then
			gl_dyn_y1=glc_y1
		end if
		if (gl_dyn_y2 > glc_y2) then
			gl_dyn_y2=glc_y2
		end if
	end if

end sub




function getSingle() as single
	Dim bchar as byte
	Dim bflag As Boolean
	dim qq as single
	dim nn as integer
	for nn=0 to 3
		do
			call GetByte(bchar,bflag)
		loop while (bflag=False)
		call RAMpoke(bchar,MemAddress(qq)+nn)
	next
	call PutByte(65)	' ACK the single
	getSingle=qq
end function

sub rxColorData()
	dim nn as integer
	dim xx as single
	for nn=0 to 15
		xx=getSingle()
		aaa(nn)=xx
	next
	call blinkred()
	for nn=0 to 15
		xx=aaa(nn)
		call PutSci(xx)		' always 13 characters
	next
end sub

sub getColorData(ByVal boffset as byte)

	' RETRIEVE COLOR DATA FROM EEPROM
	' START AT END OF 32K EEPROM AND GO BACKWARDS
	
	dim laddr as long
	laddr=32768-CLng(boffset*cvColorDataSize)
	call GetEEPROM(laddr,aaa,CInt(cvColorDataSize))

end sub

sub saveColorData(ByVal boffset as byte)

	' WRITE COLOR DATA INTO EEPROM
	' START AT END OF 32K EEPROM AND GO BACKWARDS
	
	dim laddr as long
	laddr=32768-CLng(boffset*cvColorDataSize)
	call PutEEPROM(laddr,aaa,CInt(cvColorDataSize))

end sub



sub findtube()

	' SCAN MIDDLE ROW FOR YELLOW REGION
	' (THIS IS STILL UNDER CONSTRUCTION)

	dim ii as integer
	dim jj as integer

	dim cpixr as byte
	dim cpixg as byte
	dim cpixb as byte

	dim thr as single
	dim val as single

	dim nacc1 as integer
	dim naccrun as integer
	dim naccmaxr as integer
	dim naccmaxx as integer
	dim naccmax1 as integer

	dim bpre as Boolean

	for ii=3 to 77

		' read red and green

		Register.PortA=bx0100_0100	' low CE and OE
		cpixr=Register.PinC
		Register.PortA=bx0111_0100	' high CE and OE

		Register.PortA=bx0100_0100	' low CE and OE
		cpixg=Register.PinC
		Register.PortA=bx0111_0100	' high CE and OE

		' scoot down one row and read blue
		' then scoot back up one row

		call outportb(cr_uac1,&H26)	' (0x2623) 9763=160*61+3
		call outportb(cr_uac2,&H23)

		Register.PortA=bx0100_0100	' low CE and OE
		cpixb=Register.PinC
		Register.PortA=bx0111_0100	' high CE and OE

		call outportb(cr_uac1,&H25)	' (0x2583) 9603=160*60+3
		call outportb(cr_uac2,&H83)

		val=colorMatch(cpixr,cpixg,cpixb)

		if (val>thr) then
			if (bpre=false) then
				naccrun=1
			else
				naccrun=naccrun+1
			end if
			if (naccrun>naccmaxr) then
				naccmaxr=naccrun
				naccmax1=ii
			end if
			bpre=true
		else
			bpre=false
		end if

	next

end sub



function colorMatch(ByVal br as byte, ByVal bg as byte, ByVal bb as byte) as single
	
	' *** MAHALANOBIS DISTANCE FUNCTION ***
	' THE MEAN VECTOR AND INVERSE COVARIANCE
	' MATRIX MUST BE COMPUTED OFFLINE
	' FROM A SET OF COLOR TRAINING DATA

	dim pr as single
	dim pg as single
	dim pb as single

	dim q1 as single
	dim q2 as single
	dim q3 as single

	pr=CSng(br)-aaa(9)				' [x-m]
	pg=CSng(bg)-aaa(10)
	pb=CSng(bb)-aaa(11)

	q1=pr*aaa(0)+pg*aaa(1)+pb*aaa(2)	' trans([x-m])*inv(C)
	q2=pr*aaa(3)+pg*aaa(4)+pb*aaa(5)
	q3=pr*aaa(6)+pg*aaa(7)+pb*aaa(8)

	q1=q1*pr						' trans([x-m])*inv(C)*[x-m]
	q2=q2*pg
	q3=q3*pb

	colorMatch=q1+q2+q3

end function
