# Limpet

This robot was a six-legged walker.  Although it had six legs, it only had two continuous rotation servos.  I built the body out of a Radio Shack project box but used the Crawler Kit for the Parallax BOE-bot as its legs.

https://www.parallax.com/product/30055

One servo drove 3 legs on one side of the robot.  The trick was to keep the servos moving 180 degrees out of phase with each other in order to get a good "bug" gait.  A photointerrupter could detect when a side completed its cycle.  Some timing logic would occasionally stop a servo if things were getting out of sync.  It would sometimes take a few cycles, but eventually it would settle into a smooth gate.

The robot used an IR receiver and TV remote for remote control.   It could go forward or backward, turn left or right, stop, toggle fast or slow speed, and make 3 rude noises.  The microcontroller (BrainStem GP 1.0) had a "leg server" process for the leg control and another "main" process for handling the IR receiver input.

Here it is in action:

<a href="http://www.youtube.com/watch?feature=player_embedded&v=n2eqERqqd74
" target="_blank"><img src="http://img.youtube.com/vi/n2eqERqqd74/0.jpg" 
alt="Bug Bot with Remote Control" width="240" height="180" border="10" /></a>
