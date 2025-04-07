# ThermalAssistant
Code to control an Axisflying thermal camera using a Propeller microcontroller.

Text to go with AnnotatedPcb250326a.jpg.
The blue wire connects to P08 on Propeller and RX on the camera.
The yellow wire (under the blue wire) connects to P09 on the Propeller and TX on the camera. This is a green wire on the camera's wiring harness.
The other yellow wire connects P06 to a servo output on either the flight controller or the receiver.
Depending on which USB serial device is used, a series capacitor may be needed on the DTR/reset line. The green arrow points to this optional series capacitor. When a USB to serial device doesn't require the series capacitor, the jumper circled in green should be used. This jumper bypasses the capacitor so it is ignored.
The Propeller board can be powered with either 5V or 3.3V but not both. When connected to USB, using the CP2102 board, the Propeller board runs fine off of USB power. You shouldn't power the board with another supply while also powering via USB. The 5V line can be disconnected from the CP2102 device if using a power supply other than USB.
You probably already know this but all the devices have to have a shared ground connection.
The red wire in the top right of the photo is not connected. It was part of a wire pair. I used the black wire of the pair to make one of the ground connections.

Don't use the Propeller board for power distribution. Only one 5V or 3.3V connection should be made to the board.
