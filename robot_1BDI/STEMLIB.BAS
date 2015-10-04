' BrainStem Interface Software
' Wrappers for packet TX and RX
' Created 3-13-2001


public const bstem as byte=2

public bbuff(0 to 12) as byte

public const cmdDIG_RD as byte=16
public const cmdDIG_WR as byte=17
public const cmdDIG_CFG as byte=18
public const cmdRAW_INPUT as byte=20
public const cmdSRV_ABS as byte=21
public const cmdA2D_RD as byte=27
public const cmdIR02_RD as byte=28
public const cmdINH_ON as byte=32
public const cmdINH_OFF as byte=33
public const cmdPAD_RD as byte=52
public const cmdPAD_WR as byte=53
public const cmdVM_RUN as byte=56
public const cmdVM_KILL as byte=58

sub sendPacket()
	dim ii as byte
	call PutByte(bstem)
	call PutByte(bbuff(0))
	for ii=1 to bbuff(0)
		call PutByte(bbuff(CInt(ii)))
	next
end sub

sub getPacket()

	dim bflag As Boolean
	dim bchar as byte
	dim ii as byte

	do
		call GetByte(bchar,bflag)
	loop while (bflag=False)
	do
		call GetByte(bbuff(0),bflag)
	loop while (bflag=False)
	for ii=1 to bbuff(0)
		do
			call GetByte(bbuff(CInt(ii)),bflag)
		loop while (bflag=False)
	next

end sub

sub configdigIO(ByVal bIOpin as byte, ByVal bCfg as byte)
	bbuff(0)=3
	bbuff(1)=cmdDIG_CFG
	bbuff(2)=bIOpin
	bbuff(3)=bCfg
	call sendPacket()
end sub

sub digIOwrite(ByVal bIOpin as byte, ByVal bVal as byte)
	bbuff(0)=3
	bbuff(1)=cmdDIG_WR
	bbuff(2)=bIOpin
	bbuff(3)=bVal
	call sendPacket()
end sub

function readdigIO(ByVal bIOpin as byte) as byte
	bbuff(0)=2
	bbuff(1)=cmdDIG_RD
	bbuff(2)=128+bIOpin
	call sendPacket()
	call getPacket()
	readdigIO=bbuff(3)
end function

function readpad(ByVal bpad as byte) as byte
	bbuff(0)=2
	bbuff(1)=cmdPAD_RD
	bbuff(2)=bpad
	call sendPacket()
	call getPacket()
	readpad=bbuff(2)
end function

sub writepad(ByVal bindex as byte, ByVal bval as byte)
	bbuff(0)=3
	bbuff(1)=cmdPAD_WR
	bbuff(2)=bindex
	bbuff(3)=bval
	call sendPacket()
end sub

function readIR02() as byte
	bbuff(0)=2
	bbuff(1)=cmdIR02_RD
	bbuff(2)=128
	call sendPacket()
	call getPacket()
	readIR02=bbuff(3)
end function

function readA2D(ByVal bch as byte) as byte
	bbuff(0)=2
	bbuff(1)=cmdA2D_RD
	bbuff(2)=128+bch
	call sendPacket()
	call getPacket()
	readA2D=bbuff(3)
end function

sub	fireReflex(ByVal brflx as byte)
	bbuff(0)=3
	bbuff(1)=cmdRAW_INPUT
	bbuff(2)=brflx
	bbuff(3)=0
	call sendPacket()
end sub




sub testBXBScomm()

	call	Delay(3.0)

	bbuff(0)=3
	bbuff(1)=cmdDIG_CFG
	bbuff(2)=4
	bbuff(3)=0
	call sendPacket()

	do
		call	blinkgreen()
		call Delay(0.5)
		bbuff(0)=3
		bbuff(1)=cmdDIG_WR
		bbuff(2)=4
		bbuff(3)=1
		call sendPacket()
		call blinkred()
		call Delay(1.0)

		call	blinkgreen()
		call Delay(0.5)
		bbuff(0)=3
		bbuff(1)=cmdDIG_WR
		bbuff(2)=4
		bbuff(3)=0
		call sendPacket()
		call blinkred()
		call Delay(1.0)

		bbuff(0)=3
		bbuff(1)=cmdPAD_WR
		bbuff(2)=0
		bbuff(3)=1
		call sendPacket()
		bbuff(0)=2
		bbuff(1)=cmdPAD_RD
		bbuff(2)=0
		call sendPacket()
		call getPacket()
		if (bbuff(2) <> 1) then
			do
				call blinkred()
				call Delay(0.2)
			loop
		end if

		bbuff(0)=3
		bbuff(1)=cmdPAD_WR
		bbuff(2)=0
		bbuff(3)=0
		call sendPacket()
		bbuff(0)=2
		bbuff(1)=cmdPAD_RD
		bbuff(2)=0
		call sendPacket()
		call getPacket()
		if (bbuff(2) <> 0) then
			do
				call blinkred()
				call Delay(0.2)
			loop
		end if

	loop

end sub
