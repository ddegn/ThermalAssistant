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

Instructions when using the FLiP module. 
I have not personally tested this software on a FLiP, (I don't own a FLiP myself). I assume these steps will work based on my experince with manh other Propeller boards.
1. Download in and install the Propeller Tool from: https://www.parallax.com/download/propeller-1-software/ (First in the list.)
2. Download all the spin files from this repository into a single folder or down load the archive "_DroneThermalCamera250405a - Archive [Date 2025.04.07 Time 14.19].zip" and unzip into an appropriate folder.
3. The spin files should be associated with the Propeller Tool so double clicking the top obejct "_DroneThermalCamera250405a.spin" will open the file inside the Propeller Tool.
4. Press F11 (or select Run\Compile Current\Load EEPROM).
5. Press F12 to open Parallax Serial Terminal.exe. Select the com port associated with the FLiP and enable the terminal. You should see "Press any key" prompt.
6. Pressing any key should start the program. The menu is shown as part of the start up sequence. This menu can be requested by pressing "H" (or any other non-menu key).

It is possible, the FLip will not work well powered from a source other than USB. If you can control the camera using a RC servo pulse when the FLiP is power fromn USB but not when powered from an alternate source, I will need to move the UART connection to a different set of I/O pins. If you have trouble, let me know and I'll make a modified version of the code which will work independent fron USB power.
Email me at duanedegn@gmail.com.
