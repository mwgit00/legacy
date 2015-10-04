' RAMCAM interface software
' Created 8-26-2000
'
' 10-02-2000  Blink Validated
' 10-05-2000  Image Acquired (hacked the byte shift)
' 10-21-2000  Figured out manual gain and exposure stuff for candle
' 11-28-2000  Switched to new wide-angle lens



					' RCPIN    
const c_oe	as byte=16	'    27   1 bit output enable output (active low)
const c_ce	as byte=15	'    30   1 bit camera enable output (active low)
const c_wr	as byte=14	'    31   1 bit write control output (active low)


' 4-bit register addresses with control bits high

const cr_ctrl as byte=&HF0	' $0 camera control
const cr_stat as byte=&HF1	' $1 camera status
const cr_cnfg as byte=&HF2	' $2 camera config
const cr_imsk as byte=&HF3	' $3 interrupt mask control
public const cr_rdat as byte=&HF4	' $4 ram data
const cr_i2cd as byte=&HF5	' $5 i2c data
const cr_i2ca as byte=&HF6	' $6 i2c address
const cr_i2cc as byte=&HF7	' $7 i2c control
const cr_cac1 as byte=&HF8	' $8 camera address counter[7:0]
const cr_cac2 as byte=&HF9	' $9 camera address counter[15:8]
const cr_capg as byte=&HFA	' $A camera address page
public const cr_uac1 as byte=&HFC	' $C user address counter[7:0]
public const cr_uac2 as byte=&HFD	' $D user address counter[15:8]
public const cr_uapg as byte=&HFE	' $E user address page
const cr_mask as byte=&HF0	' address mask



' camera control fields

const STRT		as byte=bx00000001
const SYNC		as byte=bx00000010
const RD_INC_ENA	as byte=bx00100000
const WR_INC_ENA	as byte=bx01000000
const LED		as byte=bx10000000

' camera status fields

const FRAME_READY	as byte=bx00000001
const I2C_RD_DONE	as byte=bx00000010
const I2C_WR_DONE	as byte=bx00000100
const I2C_ERROR	as byte=bx00001000
const TOF		as byte=bx00010000
const ACQ_PEND	as byte=bx00100000
const I2C_BUSY	as byte=bx01000000
const ACQ_BUSY	as byte=bx10000000

const EXP_WAIT	as byte=bx00000001





sub initcamera()

	'
	'==== INITIALIZE CONTROL BITS AND ADDRESS BITS
	'
	' port A is always an output

	Register.ddrA=&HFF
	Register.PortA=cr_ctrl

	'
	'==== CONFIGURE THE RAMCAM
	'
	' Grey scale, Mode 0, VV5300/VV6300
	' (docs say config register can not be read)
	' set auto increment bits and LED on
	' image starts at addr 0 (19200 byte image only needs one page)

	call outportb(cr_cnfg,&H00)
	call outportb(cr_ctrl,&HE0)

	call sr_blink

end sub

sub initcolormode()

	dim i as byte

	' 0x10 <- 0x07  output is 8 bits, auto gain, auto exposure
	' 0x11 <- bit2=1 horizontal shuffle, bit2=0 no shuffle
	' 0x14 <- 0x4D  FST=norm, QCK=fast, FST enable, (clock data only)

	call write_i2c(&H10,&H07)
	i=fn_read_i2c(&H11)
	call write_i2c(&H11,i And bx11111011)
	call write_i2c(&H14,&H4D)

	' wait for exposure update
	' then do dummy acquire to lock in gain setting

	call	acquire()
	call Delay(2.5)
	call acquire()

end sub

sub initflamemode()

	dim i as byte

	' 0x10 <- 0x00  output is 8 bits, manual gain, manual exposure
	' 0x11 <- bit2=1 horizontal shuffle, bit2=0 no shuffle
	' 0x14 <- 0x4D  FST=norm, QCK=fast, FST enable, (clock data only)
	' 0x21 <- max fine exposure (0xA8)
	' 0x23 <- low coarse exposure (0x60) (max=0x91)
	' 0x24 <- manual gain of 1 (0x00)

	call write_i2c(&H10,&H00)
	i=fn_read_i2c(&H11)
	call write_i2c(&H11, i Or bx00000100)
	call write_i2c(&H14,&H4D)
	call write_i2c(&H21,&HA8)
	call write_i2c(&H23,&H78)	' must be fine-tuned
	call write_i2c(&H24,&H00)

	' wait for exposure update
	' then do dummy acquire to lock in gain setting

	call Delay(1.0)
	call acquire()

end sub


sub acquire()

	dim bdata as byte

	' set image start address

	call outportb(cr_cac1,&H00)
	call outportb(cr_cac2,&H00)
	call outportb(cr_capg,&H00)

	' set acquire bit

	bdata=fn_inportb(cr_ctrl)
	bdata=bdata Or STRT
	call outportb(cr_ctrl,bdata)

	' wait for completion

	Do
	Loop Until ((fn_inportb(cr_stat) And ACQ_BUSY)=0)

end sub



sub imagedump()

	dim n as integer
	dim bdata as byte

	' set start address

	call outportb(cr_uac1,&H00)
	call outportb(cr_uac2,&H00)
	call outportb(cr_uapg,&H00)

	Register.PortA=cr_rdat
	Register.DDRC=&H00

	for n=1 to 19200
		Register.PortA=bx0100_0100	' low CE and OE
		bdata=Register.PinC
		Register.PortA=bx0111_0100	' high CE and OE
		call PutByte(bdata)
	next

end sub



sub sr_blink()
	dim i as byte
	dim bdata as byte
	for i=1 to 4
		bdata=fn_inportb(cr_ctrl)
		bdata=bdata Xor LED
		call outportb(cr_ctrl,bdata)
		call Delay(0.25)
	next
end sub

function fn_inportb(ByVal baddr as byte) as byte
	Register.PortA=baddr
	Register.DDRC=&H00
	call PutPin(c_ce, 0)
	call PutPin(c_oe, 0)
	fn_inportb=Register.PinC
	call PutPin(c_ce, 1)
	call PutPin(c_oe, 1)
end function

sub outportb(ByVal baddr as byte, ByVal bdata as byte)
	Register.PortA=baddr
	Register.DDRC=&HFF
	call PutPin(c_ce, 0)
	call PutPin(c_wr, 0)
	Register.PortC=bdata
	call PutPin(c_wr, 1)
	call PutPin(c_ce, 1)
end sub

sub write_i2c(ByVal i2caddr as byte, ByVal i2cdata as byte,)
	'
	' clear I2C RD bit
	' then set outgoing data
	' setting I2C address will begin write operation
	' wait for I2C write to complete
	'
	call outportb(cr_i2cc,&H00)
	call outportb(cr_i2cd,i2cdata)
	call outportb(cr_i2ca,i2caddr)
	Do
	Loop Until ((fn_inportb(cr_stat) And I2C_BUSY)=0)
end sub

function fn_read_i2c(ByVal i2caddr as byte) as byte
	'
	' set I2C RD bit
	' setting I2C address will begin read operation
	' wait for I2C read to complete
	' get incoming data
	'
	call outportb(cr_i2cc,&H01)
	call outportb(cr_i2ca,i2caddr)
	Do
	Loop Until ((fn_inportb(cr_stat) And I2C_BUSY)=0)
	fn_read_i2c=fn_inportb(cr_i2cd)
end function
