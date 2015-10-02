# Limpet

This robot was a six-legged walker.  Although it had six legs, it only had two drive motors.  I built the body out of a Radio Shack project box but used the Crawler Kit for the Parallax BOE-bot as its legs.  One servo drove 3 legs on one side of the robot.  The trick was to keep the servos moving 180 degrees out of phase with each other in order to get a good "bug" gait.  A photointerrupter could detect when a side completed its cycle.  Some timing logic would occasionally stop a servo if things were getting out of sync.  It would sometimes take a few cycles, but eventually it would settle into a smooth gate.

The robot used an IR receiver and TV remote for remote control.  It could go fast, slow, stop, turn left, turn right, and make some rude noises.
