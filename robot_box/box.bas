' {$STAMP BS1}
' BOX by Mark R. Whitney
' May 1995 (original)
' May 2009 (revived)

' Photodetector circuit:
' pin4 -> 4.7k -> (photocell || 47k) -> 0.1uF -> GND
' use scale factor of 32


' IO pin aliases

SYMBOL FF =              PIN7
SYMBOL RR =              PIN6
SYMBOL SPEEDMTR =        PIN5

SYMBOL LIGHT = 4
SYMBOL SPKR = 3
SYMBOL REDLED = 1

' names of BIT VARIABLES
SYMBOL FBIT =            BIT7
SYMBOL RBIT =            BIT6
SYMBOL TWITCH_FLAG =     BIT5    ' 0 = exit TWITCH when vel detected 1=fixed number

' names of BYTE & WORD VARIABLES
SYMBOL FLAGS=B0
SYMBOL I=B4
SYMBOL J=B5
SYMBOL K=B6
SYMBOL DIFF=B8
SYMBOL NERVE2=B10
SYMBOL NERVE1=B11

'------------------------------------------------------------------

MAIN:

'       76543210 (1 = OUTPUT, 2 = INPUT)
DIRS = %11001010

LET FBIT = 1      ' initialize all direction stuff...
LET RBIT = 0

LET J = 40        ' will be used to play tone 32 or 40 (xor with 8)

' wait 5 seconds before rolling away
' (while blinking red LED and playing ascending tone)

FOR K = 25 TO 50 STEP 5
   HIGH REDLED
   SOUND SPKR, (K, 20)
   PAUSE 260
   LOW REDLED
   PAUSE 500
NEXT K

SCOOT:

   GOSUB SR_ON
   PAUSE 500      ' roll for a while

   ' all is well if vel. detected
   IF SPEEDMTR = 1 THEN LOOK_AROUND

   ' no velocity so twitch to get unstuck
   GOSUB SR_REVDIR
   LET TWITCH_FLAG = 0
   GOSUB SR_TWITCH

   ' all is well if vel. detected
   IF SPEEDMTR = 1 THEN LOOK_AROUND

   ' else we're really stuck
   ' so shut off motor and call for help
   GOSUB SR_OFF

HELP_ME:
   SOUND SPKR, (1, 100)
   IF SPEEDMTR = 1 THEN MAIN
   PAUSE 600
   TOGGLE REDLED
   GOTO HELP_ME

LOOK_AROUND:
   ' stop...
   GOSUB SR_OFF
   PAUSE 200
   ' see if it is dark...
   POT LIGHT, 32, NERVE1
   IF NERVE1 > 250 THEN FALL_ASLEEP
   ' then check for light changes by taking 6 derivatives
   K = 6
   SAMPLE:
      PAUSE 150
      POT LIGHT, 32, NERVE1
      J = NERVE1 / 3
      SOUND SPKR, (J, 4) ' play sound indicating light level
      POT LIGHT, 32, NERVE2
      ' absolute value hackery
      LET DIFF = NERVE2 - NERVE1
      IF NERVE2 > NERVE1 THEN OKAY
      LET DIFF = NERVE1 - NERVE2
   OKAY:
      IF DIFF > 3 THEN YIKES
      LET K = K - 1
      IF K = 0 THEN SCOOT  ' no edge, then roll some more
      GOTO SAMPLE
   YIKES:
      ' twitch to flee scary light or shadow
      LET TWITCH_FLAG = 1
      GOSUB SR_TWITCH
      GOTO SCOOT


FALL_ASLEEP:
   ' snore but wake with a start when light is bright
   SOUND SPKR, (140, 50)
   PAUSE 600
   POT LIGHT, 32, NERVE1
   IF NERVE1 < 220 THEN FALL_ASLEEP_DONE
   SOUND SPKR, (240, 50)
   PAUSE 600
   POT LIGHT, 32, NERVE1
   IF NERVE1 < 220 THEN FALL_ASLEEP_DONE
   GOTO FALL_ASLEEP

FALL_ASLEEP_DONE:
   GOSUB SR_TWITCH
   GOTO SCOOT

'******************************************************************

SR_ON:
   ' apply bits to turn motor on
   FF = FBIT
   RR = RBIT
   RETURN


SR_OFF:
   ' turn motor off completely
   FF = 0
   RR = 0
   RETURN


SR_REVDIR:
   ' be sure motor outputs are both zero
   ' then toggle BOTH direction bits
   FF = 0
   RR = 0
   FBIT = FBIT ^ 1
   RBIT = RBIT ^ 1
   RETURN


SR_TWITCH:
   ' run without light sampling
   HIGH REDLED
   FOR K = 1 TO 5
      GOSUB SR_ON
      PAUSE 500
      IF SPEEDMTR = 0 THEN NO_VEL_DETECTED
      IF TWITCH_FLAG = 0 THEN QUIT_ON_VEL_DETECT
      GOTO KEEP_LOOPING
   NO_VEL_DETECTED:
      GOSUB SR_REVDIR
   KEEP_LOOPING:
   NEXT K
   QUIT_ON_VEL_DETECT:
   LOW REDLED
   RETURN