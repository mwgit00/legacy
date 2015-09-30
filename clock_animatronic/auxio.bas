' {$STAMP BS1}
' {$PORT COM1}

' Auxillary output driver for Weird Clock project
' Mark R. Whitney
' June 11, 2006

' constants
SYMBOL step_delay = 25    ' delay between activations in stepper sequence
SYMBOL link = 0           ' input pin for serial IO
SYMBOL out_mouth = 1      ' mouth control
SYMBOL out_nose = 6       ' nose control
SYMBOL out_hours = 7      ' hours LED control

' variable aliases
SYMBOL b_rx1 = B1         ' serial command code
SYMBOL b_rx2 = B2         ' serial command parameter
SYMBOL b_rx3 = B3         ' serial command parameter
SYMBOL b_tmp = B4


'---------------------------------------------------------------------

init:
  LET DIRS = %01111111    ' 0 is input, 1-7 are outputs
  LET PINS = %00000000    ' all outputs start low (off)

main:
  SERIN link, N2400, b_rx1, b_rx2, b_rx3
  LOOKDOWN b_rx1, ("AXYZ"), b_tmp
  BRANCH b_tmp, (main_step, main_ctrl_mouth, main_ctrl_nose, main_ctrl_hours_LED)
main_unknown_command:
  PAUSE 100                   ' just do a pause if command is invalid
main_done:
  SEROUT link, N2400, ("0")   ' signal that command completed
  GOTO main

'********************************************************************

' pulse the mouth with short burst of PWM then set it low again
main_ctrl_mouth:
  PWM out_mouth, b_rx2, b_rx3
  LOW out_mouth
  GOTO main_done

' pulse the nose with short burst of PWM then set it low again
main_ctrl_nose:
  PWM out_nose, b_rx2, b_rx3
  LOW out_nose
  GOTO main_done

' hours LED remains in specified state after subroutine is done
main_ctrl_hours_LED:
  IF b_rx2 > 0 THEN main_ctrl_hours_LED_on
main_ctrl_hours_LED_off:
  LOW out_hours
  GOTO main_done
main_ctrl_hours_LED_on:
  HIGH out_hours
  GOTO main_done

' advance the stepper motor
main_step:
  LET b_tmp = PINS & %11000011

  LET b_tmp = b_tmp | %00101000  ' seq=1010
  LET PINS = b_tmp
  PAUSE step_delay

  LET b_tmp = b_tmp ^ %00001100  ' seq=1001
  LET PINS = b_tmp
  PAUSE step_delay

  LET b_tmp = b_tmp ^ %00110000  ' seq=0101
  LET PINS = b_tmp
  PAUSE step_delay

  LET b_tmp = b_tmp ^ %00001100  ' seq=0110
  LET PINS = b_tmp
  PAUSE step_delay

  LET b_tmp = b_tmp & %11000011
  LET PINS = b_tmp
  GOTO main_done
