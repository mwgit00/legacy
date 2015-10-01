' {$STAMP BS1}
' David Patterson's Clock by Mark R. Whitney
' June 2009


' DS1302 clock chip constants
SYMBOL regts = $80
SYMBOL regtm = $82
SYMBOL regth = $84
SYMBOL regctrl = $8E
SYMBOL regram0 = $C0
SYMBOL regram1 = $C2


' IO pin aliases
SYMBOL XRST = 0  ' DS1302 reset
SYMBOL XDIO = 1  ' DS1302 data
SYMBOL XCLK = 2  ' DS1302 data clock
SYMBOL XSRX = 3  ' serial receive
SYMBOL XSTX = 4  ' serial transmit
SYMBOL XSOL = 5  ' solenoid on-off
SYMBOL XUSR = 6  ' user mode switch


' names of BIT VARIABLES
SYMBOL VDIO = PIN1  ' DS1302 data
SYMBOL VUSR = PIN6  ' user mode switch


' names of BYTE & WORD VARIABLES
SYMBOL alarmHH = B4
SYMBOL alarmMM = B5
SYMBOL K = B6
SYMBOL tempHH = B7
SYMBOL tempMM = B8
SYMBOL noChime = B9
SYMBOL RANX = W5       ' b10 and b11



'------------------------------------------------------------------

main:

  ' B1 starts out as 0
  ' clear write-protect bit so we can set time if desired
  B0 = regctrl
  GOSUB sr_tx


alarm_init:
  ' load saved alarm time into alarmHH:alarmMM
  B0 = regram0
  GOSUB sr_rx
  alarmHH = B0 & $7F  ' low 7 bits are BCD hours
  noChime = B0 & $80  ' set high bit for no chime
  B0 = regram1
  GOSUB sr_rx
  alarmMM = B0


alarm_check:
  ' do a check every 600ms
  PAUSE 600
  ' user mode switch input is normally high till switch closed
  IF VUSR = 0 THEN cmd_entry
alarm_check_get_time:
  ' read hours, minutes, seconds
  ' seconds value will stay in B0
  B0 = regth
  GOSUB sr_rx
  tempHH = B0
  B0 = regtm
  GOSUB sr_rx
  tempMM = B0
  B0 = regts
  GOSUB sr_rx
  ' dump BCD HH:MM:SS and alarm HH:MM
  SEROUT XSTX, T2400, (#tempHH, ":", #tempMM, ":", #B0, 32, #alarmHH, ":", #alarmMM, 32, #noChime, 13)
alarm_check_compare:
  ' only do HH:MM check after seconds wraps around to 0 or 1
  IF B0 > 0 THEN alarm_check
alarm_check_compare_hh_mm:
  IF tempHH = alarmHH AND tempMM = alarmMM THEN alarm_activate
alarm_check_chime:
  ' if no chime desired or minutes = 0 then skip chime
  IF noChime > 0 OR tempMM <> 0 THEN alarm_check
  ' shake solenoid once to chime
  HIGH XSOL
  PAUSE 200
  LOW XSOL
  GOTO alarm_check

alarm_activate:
  ' wiggle solenoid randomly (around 40 seconds or so)
  FOR K = 1 TO 60
    RANDOM W5
    W0 = W5 // 29 * 11 + 80 ' 80ms to 399ms seems about right
    HIGH XSOL
    PAUSE W0
    LOW XSOL
    PAUSE W0
  NEXT K
  GOTO alarm_check


cmd_entry:

  ' output prompt for BCD input of {HH MM [noChime | alarmHH] alarmMM} <enter>
  ' user must input decimal equivalent of BCD values, space-delimited
  SERIN XSRX, T2400, #B2, #B3, #B1, #alarmMM

  ' B1 has noChime (bit 7) alarmHH (bits 0-6)
  ' write alarm time [noChime | alarmHH]:alarmMM (in BCD) to ram[0]:ram[1]
  B0 = regram0
  GOSUB sr_tx
  B0 = regram1
  B1 = alarmMM
  GOSUB sr_tx

  ' time of 255 is code for skipping time set step
  ' in case user just wants to set alarm
  IF B2 = 255 THEN alarm_init

  ' write new time B2:B3 to HH:MM (in BCD)
  B0 = regth
  B1 = B2
  GOSUB sr_tx
  B0 = regtm
  B1 = B3
  GOSUB sr_tx

  ' 0 the seconds
  ' this also clears clock-halt
  B0 = regts
  B1 = 0
  GOSUB sr_tx

  GOTO alarm_init



'******************************************************************
' DS1302 CLOCK CHIP CONTROL ROUTINES

' writes B0, B1 to clock
' entry preparation:
' - load address into B0
' - load outgoing datum into B1
sr_tx:
  HIGH XRST
  GOSUB sr_tx_byte
  B0 = B1
  GOSUB sr_tx_byte
  LOW XRST
  RETURN


' transmits B0 to clock
' entry preparation:
' - load B0 with data
sr_tx_byte:
  ' we are sending output to clock
  LOW XDIO
  OUTPUT XDIO
  ' B0 bits go out starting with LSB
  ' set bit then pulse the clock
  ' we set data on rising clock
  FOR K = 1 TO 8
    VDIO = BIT0
    PULSOUT XCLK, 1
    B0 = B0 / 2
  NEXT K
  RETURN


' reads datum at B0 from clock, puts datum in B0
' entry preparation:
' - load address into B0
sr_rx:
  BIT0 = 1
  HIGH XRST
  GOSUB sr_tx_byte
  ' now we are getting input from chip
  INPUT XDIO
  ' we get data on falling clock
  ' previous write already gave us a falling clock
  ' which means first bit of read is already at DIO
  ' so get bit then pulse the clock
  FOR K = 1 TO 8
    B0 = B0 / 2
    BIT7 = VDIO
    PULSOUT XCLK, 1
  NEXT K
  LOW XRST
  RETURN