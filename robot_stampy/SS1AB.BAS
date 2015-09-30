' Stampy Step Controller 1C
' Mark R. Whitney
' November 27, 1998
' January 10, 1999
'
' 11-27-98 ankle shims added -- hip home updated
' 11-28-98 serial parameters
' 1-10-99 made relative torso movement routine calculate increment
' 1-13-99 ankle overhaul
' 1-15-99 step motion re-evaluation to keep feet from jamming
' 2-14-99 modified all movement routines
'         added comm support for fan stuff
'         servo controller now manages body
' 3-7-99  decrease beepcount to 16
'         added routine for visor
'         transmission params use bit addressable b0 & b1
' 3-22-99 visor stuff removed (obsolete)
' 4-10-99 this is about as good as it is gonna get


symbol ACK=65		' ACK is "A"
symbol LINK=5		' serial connection to BS2
symbol FAN=6		' fan control
symbol FAN_PIN=pin6	' 
symbol GREEN_LIGHT=0	' pin to control ready light

symbol BEEP=pin4	' pin for detecting beep tone
symbol beepcount=16	' number of beep tone detections for valid start

symbol rhip=4		' SSC-1 servo controller codes
symbol rank=5
symbol lhip=1
symbol lank=3
symbol body=2


' b3 & b4 are subroutine parameters!!!


symbol code=b5		' transmission code
symbol param1=b0	' transmission params
symbol param2=b1


symbol rank_pos=b8	' calculated  ankle positions
symbol lank_pos=b9




symbol body_home=120

symbol rhip_home=115	' hip home positions
symbol rhip_rbal=160

symbol lhip_home=115
symbol lhip_lbal=70


symbol rank_home=150	' ankle home positions
symbol lank_home=155

symbol stepdelay=250	' barely enough is 250
symbol stepdelay1=1	'100 ???
symbol stepdelay2=1	'150 ???
symbol hipdelay=1	'????
symbol step_delay=w5


'-------------------------------------------------------------------

' be sure pins are all zero
' leg joints and torso to home positions
' slight delay to let things settle

let pins=0
serout 3,n2400,(255,rhip,rhip_home,255,lhip,lhip_home,255,rank,rank_home,255,lank,lank_home,255,body,body_home)
pause 500


START:
	high GREEN_LIGHT		' ready to go!!!
	LISTEN_FOR_BEEP:
		for b3=1 to beepcount
			' several consecutive lows are
			' required for a valid start beep
			if BEEP=1 then LISTEN_FOR_BEEP
		next b3
	low GREEN_LIGHT
	serout LINK,N2400,(ACK)		' tell BS2 to start


LOOP:
	serin LINK,N2400,code,param1,param2
	branch code,(CASE_L,CASE_R,CASE_T,CASE_F,START,CASE_J,CASE_X)
SEND_ACK:
	serout LINK,N2400,(ACK)		' tell BS2 command complete
	goto LOOP

CASE_L:
	let rank_pos=rank_home+param1
	let lank_pos=lank_home+param2
	gosub sr_step_lbal
	goto SEND_ACK
CASE_R:
	let rank_pos=rank_home+param1
	let lank_pos=lank_home+param2
	gosub sr_step_rbal
	goto SEND_ACK
CASE_T:
	serout 3,n2400,(255,body,param1)
	goto SEND_ACK
CASE_F:
	let w3=param1*100	' input is 10ths of a second
	high FAN
	pause w3
	low FAN
	goto SEND_ACK
CASE_J:
	serout 3,n2400,(255,param1,param2)
	goto SEND_ACK
CASE_X:
	toggle GREEN_LIGHT
	goto SEND_ACK

'----------------------------------------- motion subroutines

sr_step_lbal:
	serout 3,n2400,(255,lhip,lhip_lbal,255,rhip,lhip_lbal)
	pause stepdelay1
	serout 3,n2400,(255,lank,lank_pos)
	serout 3,n2400,(255,rank,rank_pos)
	pause stepdelay
	serout 3,n2400,(255,rhip,lhip_home)
	pause hipdelay
	serout 3,n2400,(255,lhip,lhip_home)
	pause stepdelay2
return

sr_step_rbal:
	serout 3,n2400,(255,rhip,rhip_rbal,255,lhip,rhip_rbal)
	pause stepdelay1
	serout 3,n2400,(255,rank,rank_pos)
	serout 3,n2400,(255,lank,lank_pos)
	pause stepdelay
	serout 3,n2400,(255,lhip,rhip_home)
	pause hipdelay
	serout 3,n2400,(255,rhip,rhip_home)
	pause stepdelay2
return
