' Roachbot II-XB
' March 6, 1998
' 3-6-98	relay to switch motor direction
'		1 transistor for on/off
' 3-14-98	diode for both servo and drive motor current paths
'		220uF cap between servo diode cathode & ground
'		(hopefully this will isolate & filter servo supply)
' 4-12-98	IR prox detector, beeper, light sensor
' 5-2-99	new battery clips & overhaul
' 8-4-99	scrapped old IR detector and added GP2D02



symbol person=0			' I person detector input
symbol proxbit=pin1		' I prox detector data bit
symbol proxvin=2		' O prox detector clock
symbol steer= 3			' O steering servo output
symbol tach= 4			' I tachometer input
symbol motorpin=5		' O motor on-off output
symbol relaypin=6		' O motor direction output
symbol beeper=7			' O beeper output

symbol wheelpos5=b5		' ranges from 100 to 180
symbol tachtimer_w3=w3

symbol goLL=180
symbol goL=160
symbol ctr=140
symbol goR=120
symbol goRR=100

symbol potscale=50
symbol samplenum=8
symbol samplethresh=6		' 6 out of 8 samples is a hit
symbol proxpin=pin1
symbol personpin=pin0

'--------------------------------------------------------------

INIT:

		' initialize IO port

	'   pins          76543210
	'   dirs  76543210
	let port=%1110110000000000

		' center the steering wheel

	let wheelpos5=ctr
	gosub sr_steer_9

		' chirp a few times to indicate status
		' and give people detector time to settle

	let b9=10
	gosub sr_chirp_89


hugwall:
	gosub sr_prox_89			' do a prox check
	if b8<90 then noIRdetect
		let wheelpos5=goL		' something close so goL
		goto endIRdetect
	noIRdetect:
		let wheelpos5=goR		' nothing close so goR
	endIRdetect:
	gosub sr_steer_9		' steer based on prox
	high motorpin			' turn motor on
	pause 100			' pause to allow some acceleration

scootloop:
	pulsin tach,0,tachtimer_w3         ' check velocity
	if tachtimer_w3=0 then getunstuck  ' pulsin should introduce delay

stopandlook:
	low motorpin					' turn motor off
	for b7=1 to 50
		if personpin=1 then frightened		' sample world
		pause 10
	next b7
	goto hugwall	' all is well so scoot again

frightened:
	goto hugwall
	let wheelpos5=goLL
	gosub sr_steer_9
	high relaypin
	high motorpin
	pause 1500		' do hard turn around
	low motorpin
	low relaypin
	high beeper
	pause 200		' beep at enemy
	low beeper
	goto hugwall		' resume wandering


'
'
'
' try back & forth motion 3 times to get unstuck
' if this fails, then end program
'
getunstuck:
	low relaypin
	low motorpin
	for b2=0 to 5
		let b3=b2 & %00000001
		lookup b3,(goRR,goLL),wheelpos5
		gosub sr_steer_9		' hard right on even
		toggle relaypin			' reverses on even
		high motorpin
		pause 100			' accelerate some...
		pulsin tach,0,tachtimer_w3	' check motion
		low motorpin
		if tachtimer_w3<>0 and b3=1 then goagain
	next b2
	goto stuckforgood

	goagain:
		low relaypin
		goto hugwall           ' then continue scooting

stuckforgood:
	let wheelpos5=ctr
	gosub sr_steer_9
chirp_for_help:
	let b9=2
	gosub sr_chirp_89
	pause 1000
	goto chirp_for_help
'---------------------------------------------------------------



'**********************************************************
' sends a bunch of steering pulses to servo to make
' sure it reaches the desired final position
'
' this subroutine modifies b11
' local 
sr_steer_9:
	for b11=1 to 20
		pulsout steer,wheelpos5
		pause 20
	next b11
return



'**********************************************************
' IR prox detector routine - returns distance value
'
' this subroutine modifies b8,b9
' local:    b9
' inputs:   none
' outputs:  b8 has distance value
'
sr_prox_89:
	low proxvin	' reset the GP2D02
	pause 70
	let b8=0
	for b9=1 to 8
		pulsout proxvin,10
		let b8=b8 * 2
		let b8=b8 | proxbit
		pause 1
	next b9
	high proxvin
	pause 2
return



'**********************************************************
' Chirping routine - emit specified number of chirps
'
' this subroutine modifies b8,b9
' local:    b8
' inputs:   b9 is number of chirps
' outputs:  none
'
sr_chirp_89:
	for b8=1 to b9
		pulsout beeper,100
		pause 500
	next b8
	return
