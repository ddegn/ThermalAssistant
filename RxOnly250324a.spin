{{      RxOnly250324a.spin
─────────────────────────────────────────────────
File: Parallax Serial Terminal.spin
Version: 1.0
Copyright (c) 2009 Parallax, Inc.
See end of file for terms of use.

Authors: Jeff Martin, Andy Lindsay, Chip Gracey
─────────────────────────────────────────────────
}}

{
HISTORY:
  This object is made for direct use with the Parallax Serial Terminal; a simple serial communication program
  available with the Propeller Tool installer and also separately via the Parallax website (www.parallax.com).

  This object is heavily based on FullDuplexSerialPlus (by Andy Lindsay), which is itself heavily based on
  FullDuplexSerial (by Chip Gracey).

USAGE:
  • Call Start, or StartRxTx, first.
  • Be sure to set the Parallax Serial Terminal software to the baudrate specified in Start, and the proper COM port.
  • At 80 MHz, this object properly receives/transmits at up to 250 Kbaud, or performs transmit-only at up to 1 Mbaud.

}

CON 'Pst250317a
''
''     Parallax Serial Terminal
''    Control Character Constants
''─────────────────────────────────────
  CS = 16  ''CS: Clear Screen
  CE = 11  ''CE: Clear to End of line
  CB = 12  ''CB: Clear lines Below

  HM =  1  ''HM: HoMe cursor
  PC =  2  ''PC: Position Cursor in x,y
  PX = 14  ''PX: Position cursor in X
  PY = 15  ''PY: Position cursor in Y

  NL = 13  ''NL: New Line
  LF = 10  ''LF: Line Feed
  ML =  3  ''ML: Move cursor Left
  MR =  4  ''MR: Move cursor Right
  MU =  5  ''MU: Move cursor Up
  MD =  6  ''MD: Move cursor Down
  TB =  9  ''TB: TaB
  BS =  8  ''BS: BackSpace

  BP =  7  ''BP: BeeP speaker

CON

   BUFFER_LENGTH = 64                                   'Recommended as 64 or higher, but can be 2, 4, 8, 16, 32, 64, 128 or 256.
   BUFFER_MASK   = BUFFER_LENGTH - 1
   MAXSTR_LENGTH = 49                                   'Maximum length of received numerical string (not including zero terminator).

VAR

  long  rx_head                                         '59 contiguous longs (must keep order)
  long  rx_tail
  long  rx_pin
  long  bit_ticks
  long  buffer_ptr

  byte  rx_buffer[BUFFER_LENGTH]                        'Receive and transmit buffers


PUB StartRx(rxpin, baudrate) : cog
{{Start serial communication with designated pins, mode, and baud.
  Parameters:
    rxpin    - input pin; receives signals from external device's TX pin.
    baudrate - bits per second.
  Returns    : True (non-zero) if cog started, or False (0) if no cog is available.}}

  longmove(@rx_pin, @rxpin, 2)
  bit_ticks := clkfreq / baudrate
  buffer_ptr := @rx_buffer
  cog := cognew(@entry, @rx_head)

PUB Rx : bytechr
{{Receive single-byte character.  Waits until character received.
  Returns: $00..$FF}}

  repeat while (bytechr := RxCheck) < 0

PUB RxFlush
{{Flush receive buffer.}}

  repeat while rxcheck => 0

PUB RxCheck : bytechr
{Check if character received; return immediately.
  Returns: -1 if no byte received, $00..$FF if character received.}

  if rx_tail == rx_head
    bytechr := -1
  else
    bytechr := rx_buffer[rx_tail]
    rx_tail := (rx_tail + 1) & BUFFER_MASK

DAT

'***********************************
'* Assembly language serial driver *
'***********************************

                        org
'
'
' Entry
'
entry                   mov     rxHeadAddress,par                'get structure address

                        mov     tempAddress, rxHeadAddress

                        'We don't care about the tail.

                        add     tempAddress, #8
                        rdlong  tempVariable, tempAddress                 'get rx_pin
                        mov     rxMask, #1
                        shl     rxMask, tempVariable

                        add     tempAddress, #4
                        rdlong  bitTicks, tempAddress           'We don't need tempAddress or tempVariable anymore.
                        mov     rxHeadCog, #0
                        add     tempAddress, #4                'get buffer_ptr
                        rdlong  rxBufferAddress, tempAddress            'We don't need tempAddress or tempVariable anymore.

                        mov     halfBitTime, bitTicks
                        shr     halfBitTime, #1

'
'                      'Watch for start bit.
' Receive
'
receive                 test    rxMask,ina wc
        if_c            jmp     #receive

                        mov     rxCnt, cnt  'Start time of byte. Start of start bit.

                        add     rxCnt, halfBitTime 'bitAndHalfTime

                        mov     rxBits, #9             'ready to receive byte

rxBit                   add     rxCnt, bitTicks        'ready next bit period

waitForBit              mov     bitTimer, rxCnt              'check if bit receive period done
                        sub     bitTimer, cnt
                        cmps    bitTimer, #0 wc
        if_nc           jmp     #waitForBit

                        test    rxMask, ina wc    'receive bit on rx pin
                        rcr     rxData, #1
                        djnz    rxBits, #rxBit

                        shr     rxData, #32-9          'justify and trim received byte
                        and     rxData, #$FF

                        mov     activeBufferPtr, rxBufferAddress
                        add     activeBufferPtr, rxHeadCog

                        wrbyte  rxData, activeBufferPtr

                        add     rxHeadCog, #1
                        and     rxHeadCog, #BUFFER_MASK
                        wrlong  rxHeadCog, rxHeadAddress
                        jmp     #receive              'byte done, receive next byte
'
'
' Uninitialized data
'
rxHeadAddress           res 1
activeBufferPtr         res 1
tempAddress             res 1
tempVariable            res 1
rxBytes                 res 1
bitTicks                res 1
bitTimer                res 1
halfBitTime             res 1
rxMask                  res 1
rxBufferAddress         res 1
rxData                  res 1
rxBits                  res 1
rxCnt                   res 1
rxHeadCog               res 1


{{

┌──────────────────────────────────────────────────────────────────────────────────────┐
│                           TERMS OF USE: MIT License                                  │
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │                                            │
│                                                                                      │                                               │
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │                                                │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     │
│OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        │
│SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}