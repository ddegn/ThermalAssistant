{{RC_Receiver.spin

Code modified by Duane Degn August 2012 to use "Gold Standard" naming conventions.
Code was also modified by Duane Degn to be able to use any of the Propeller I/O pins.

Code was originally named "RC_Receiver_6". Jason Dorie had modified it from some other code.
Many of the notes below are from the original object.
The original code could only use pins 0 - 5.

-----------------------------------------------------------------------------------------------
Read servo control pulses from a generic R/C receiver, modified to handle ONLY 6 pins
Use 4.7K resistors (or 4050 buffers) between each Propeller input and receiver signal output.

                   +5V
   ┌──────────────┐│     4.7K
 ──┤   R/C     [] ┣┼──────────• Propeller input(s) 
 ──┤ Receiver  [] ┣┘    Signal
 ──┤Channel(s) [] ┣┐
   └──────────────┘│
                   GND(VSS)

 Note: +5 and GND on all the receiver channels are usally interconnected,
 so to power the receiver only one channel need to be connected to +5V and GND.
-----------------------------------------------------------------------------------------------

This code is modified from its original version to read only 6 RC inputs, not 8.
The getrc function was modified to return values centered at zero instead of 1500.


}}
CON

  POSSIBLE_CHANNELS = 6         ' Max allowed is six
  LOWEST_POSSIBLE_PIN = 0
  HIGHEST_POSSIBLE_PIN = 31
  CENTERED_PULSE = 1500
  LOW_PULSE = 1100
  THROTTLE_CHANNEL = 0
  
VAR

  long cog
  long pulseTics[POSSIBLE_CHANNELS]
  long pinMaskHub
  long individualMaskHub[POSSIBLE_CHANNELS]
  long microSecond
  
PRI SetPins(pinMask) | localIndex, lowestArrayElement
'' Set pinmask for active input pins
'' Example: SetPins(%0000_0010_0000_0011_0000_0000_0010_0001) to read from
'' pins 0, 5, 16, 17 and 25 
  pinMaskHub := pinMask
  lowestArrayElement := POSSIBLE_CHANNELS - 1
  repeat localIndex from POSSIBLE_CHANNELS - 1 to 0
    result := >|pinMask
    if result  
      individualMaskHub[localIndex] := |<(result - 1)
      pinMask -= individualMaskHub[localIndex]
      lowestArrayElement := localIndex
  if lowestArrayElement
    longmove(@individualMaskHub, @individualMaskHub + (4 * lowestArrayElement), POSSIBLE_CHANNELS - lowestArrayElement)
    
PUB Start(pinMask)
'' Start driver start a cog and returns the cog's ID number plus one.
'' This object assumes the lowest pin numbers corresponds with the lowest
'' channels.
'' For example: Start(%0000_0010_0000_0011_0000_0000_0010_0001) will store
'' pulses received by P0 in PulseTics[0], pulses received by P5 will be stored
'' in PulseTics[1], PulseTics[4] will store the pulses received by P25 and
'' PulseTics[5] will remain in its initialized "centered" state.

  microSecond := clkfreq / 1_000_000

  Stop

  SetPins(pinMask)
 
  repeat result from 1 to 5
    if result == THROTTLE_CHANNEL
      pulseTics[result] := LOW_PULSE * microSecond                             ' throttle pin set low
    else  
      pulseTics[result] := microSecond * CENTERED_PULSE         ' Center pulses
      
  result := cog := cognew(@enter, @pulseTics) + 1
  
PUB Stop
'' Stop driver and release cog

  if cog
    cogstop(cog~ - 1)

PUB BuildMask(pin0, pin1, pin2, pin3, pin4, pin5) | pinIndex 
'' This method creates a bit mask from individual I/O pin numbers.
'' This is just to make it easier to change pins used in parent
'' object. The channel numbers go from lowest pins to highest
'' pins.
'' The mask is returned to the calling method. This mask may
'' then be used when calling the start method of this object.
'' Use -1 for pins not used.

  pinIndex := @pin0
  repeat POSSIBLE_CHANNELS
    if long[pinIndex] => LOWEST_POSSIBLE_PIN and long[pinIndex] =< HIGHEST_POSSIBLE_PIN
      result += 1 << long[pinIndex]
    pinIndex += 4 

PUB Get(channel) 
'' Get receiver servo pulse width in µs. 

  result := pulseTics[channel] / microSecond         
 
PUB GetRc(channel) : value
'' Get receiver servo pulse width with a centered
'' pulse being used as zero.
'' The number of microseconds pulse is from the
'' centered value is returned.
'' Example: If a 1000us pulse is received, then
'' the return value will be -500.
 
  result := Get(channel) - CENTERED_PULSE
 
DAT
                        org 0

enter                   mov     tempPtr, par            ' Get data pointer
                        add     tempPtr, #4 * POSSIBLE_CHANNELS ' Point to pinMaskHub
                        rdlong  pinMaskCog, tempPtr     ' Read pinMaskHub
                        andn    dira, pinMaskCog        ' Set input pins
                        add     tempPtr, #4             ' Point to individualMaskHub[0]
                        rdlong  individualMask0, tempPtr
                        add     tempPtr, #4             
                        rdlong  individualMask1, tempPtr
                        add     tempPtr, #4             
                        rdlong  individualMask2, tempPtr
                        add     tempPtr, #4             
                        rdlong  individualMask3, tempPtr
                        add     tempPtr, #4             
                        rdlong  individualMask4, tempPtr
                        add     tempPtr, #4             
                        rdlong  individualMask5, tempPtr  

                        mov     newPinState, #0         ' initialize pin states
'=================================================================================

:loop                   mov     previousPinState, newPinState ' Store previous pin status
                        waitpne newPinState, pinMaskCog ' Wait for change on pins
                        mov     newPinState, ina        ' Get new pin status 
                        mov     changeTime, cnt         ' Store change cnt                           
                        and     newPinState, pinMaskCog ' Remove unrelevant pin changes
{
previousPinState 1100
newPinState    1010
-------------
!previousPinState 0011
&newPinState   1010
=       0010 POS edge

previousPinState 1100
&!newPinState  0101
=       0100 NEG edge     
}
                                                        ' Mask for POS edge changes
                        mov     positiveEdges, newPinState
                        andn    positiveEdges, previousPinState
                         
                                                        ' Mask for NEG edge changes
                        andn    previousPinState, newPinState                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
'=================================================================================

:pos                    tjz     positiveEdges, #:neg    ' Skip if no POS edge changes
'Pin 0
                        test    positiveEdges, individualMask0 wz ' Change on pin?
              if_nz     mov     positiveEdgeTime0, changeTime ' Store POS edge change cnt
'Pin 1
                        test    positiveEdges, individualMask1 wz
              if_nz     mov     positiveEdgeTime1, changeTime
'Pin 2
                        test    positiveEdges, individualMask2 wz
              if_nz     mov     positiveEdgeTime2, changeTime
'Pin 3
                        test    positiveEdges, individualMask3 wz
              if_nz     mov     positiveEdgeTime3, changeTime
'Pin 4
                        test    positiveEdges, individualMask4 wz
              if_nz     mov     positiveEdgeTime4, changeTime
'Pin 5
                        test    positiveEdges, individualMask5 wz
              if_nz     mov     positiveEdgeTime5, changeTime

'=================================================================================

:NEG                    tjz     previousPinState, #:loop ' Skip if no NEG edge changes
'Pin 0
                        mov     tempPtr, par        ' Get data pointer
                        test    previousPinState, individualMask0 wz ' Change on pin 0?
              if_nz     mov     endOfPulseTime, changeTime ' Get NEG edge change cnt
              if_nz     sub     endOfPulseTime, positiveEdgeTime0 ' Get pulse width
              if_nz     wrlong  endOfPulseTime, tempPtr ' Store pulse width
'Pin 1
                        add     tempPtr, #4         ' Get next data pointer
                        test    previousPinState, individualMask1 wz ' ...
              if_nz     mov     endOfPulseTime, changeTime
              if_nz     sub     endOfPulseTime, positiveEdgeTime1
              if_nz     wrlong  endOfPulseTime, tempPtr
'Pin 2
                        add     tempPtr, #4
                        test    previousPinState, individualMask2 wz
              if_nz     mov     endOfPulseTime, changeTime
              if_nz     sub     endOfPulseTime, positiveEdgeTime2
              if_nz     wrlong  endOfPulseTime, tempPtr
'Pin 3
                        add     tempPtr, #4
                        test    previousPinState, individualMask3 wz
              if_nz     mov     endOfPulseTime, changeTime
              if_nz     sub     endOfPulseTime, positiveEdgeTime3
              if_nz     wrlong  endOfPulseTime, tempPtr
'Pin 4
                        add     tempPtr, #4
                        test    previousPinState, individualMask4 wz
              if_nz     mov     endOfPulseTime, changeTime
              if_nz     sub     endOfPulseTime, positiveEdgeTime4
              if_nz     wrlong  endOfPulseTime, tempPtr
'Pin 5
                        add     tempPtr, #4
                        test    previousPinState, individualMask5 wz
              if_nz     mov     endOfPulseTime, changeTime
              if_nz     sub     endOfPulseTime, positiveEdgeTime5
              if_nz     wrlong  endOfPulseTime, tempPtr

                        jmp     #:loop     ' 53 instructions

                        'fit Mhz ' Check for at least 1µs resolution with current clock speed

'=================================================================================

pinMaskCog              res 1
individualMask0         res 1
individualMask1         res 1
individualMask2         res 1
individualMask3         res 1
individualMask4         res 1
individualMask5         res 1

changeTime              res 1
               
newPinState             res 1
previousPinState        res 1
positiveEdges           res 1
endOfPulseTime          res 1

tempPtr                 res 1

positiveEdgeTime0       res 1
positiveEdgeTime1       res 1
positiveEdgeTime2       res 1
positiveEdgeTime3       res 1
positiveEdgeTime4       res 1
positiveEdgeTime5       res 1

                        fit 496