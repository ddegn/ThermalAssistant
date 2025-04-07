DAT  objectName         byte "LedSerial250308a", 0

CON
{{

  250308a Change buffer sizes.


}}
CON '' Added by DWD
'' In order to use the port number to keep track of ASCII protocol and raw protocol
'' The port number 5 will be added to the port number to indicate the port
'' needs to be changed.

CON

 { NOMODE                        = %000000
  INVERTRX                      = %000001
  INVERTTX                      = %000010
  OCTX                          = %000100
  NOECHO                        = %001000
  INVERTCTS                     = %010000
  INVERTRTS                     = %100000

  PINNOTUSED                    = -1                    'tx/tx/cts/rts pin is not used
  DEFAULTTHRESHOLD              = 0                     ' zero defaults to 3/4 of buffer length

  BAUD1200                      = 1200
  BAUD2400                      = 2400
  BAUD4800                      = 4800
  BAUD9600                      = 9600
  BAUD19200                     = 19200
  BAUD38400                     = 38400
  BAUD57600                     = 57600
  BAUD115200                    = 115200  }

' The following constants declare the sizes of the rx and tx buffers.
' Enter in the needed size in bytes for each rx and tx buffer
' These values can be any size within available memory. They do not have to be a power of two.
' Unused buffers can be reduced to 1 byte.
  RX_SIZE0                      = 64  ' receive buffer allocations
  RX_SIZE1                      = 128 '160
  RX_SIZE2                      = 128 '160
  RX_SIZE3                      = 128 '

  TX_SIZE0                      = 32  ' transmit buffer allocations
  TX_SIZE1                      = 64
  TX_SIZE2                      = 64
  TX_SIZE3                      = 32


  RXTX_BUFSIZE                  = (TX_SIZE0 + TX_SIZE1 + TX_SIZE2 + TX_SIZE3 + RX_SIZE0 + RX_SIZE1 + RX_SIZE2 + RX_SIZE3)
                                 ' total buffer footprint in bytes
                                 ' 77 longs, 308 bytes are available for buffers within the hub footprint of the object
                                 ' the final instruction in this program allocates additional buffer space beyond that if necessary
                                 ' to accomodate all of the buffers.
                                 ' if the sum totals to 308, then the buffers exactly fit within the object footprint.


{PUB Init
''Always call init before adding ports
'' messageCountAddress should be the memory location
'' of a long sized variable used to hold the ongoing
'' message count. This count will be encreased with
'' every end of message character received on port 0.

  Stop

  bytefill(@startfill, 0, (@endfill-@startfill))        ' initialize head/tails,port info and hub buffer pointers
  return @rxsize                                        ' TTA returns pointer to data structure, buffer sizes.
   }
PUB GetObjectName

  result := @objectName

PUB AddPort(port, rxpin, txpin, mode, baudrate)
'' Call AddPort to define each port
'' port 0-3 port index of which serial port
'' rx/tx/cts/rtspin pin number                          XXX#PINNOTUSED if not used
'' rtsthreshold - buffer threshold before rts is used   XXX#DEFAULTTHRSHOLD means use default
'' mode bit 0 = invert rx                               XXX#INVERTRX
'' mode bit 1 = invert tx                               XXX#INVERTTX
'' mode bit 2 = open-drain/source tx                    XXX#OCTX
'' mode bit 3 = ignore tx echo on rx                    XXX#NOECHO
'' mode bit 4 = invert cts                              XXX#INVERTCTS
'' mode bit 5 = invert rts                              XXX#INVERTRTS
'' baudrate

  if cog or (port > 3)
    abort
  if rxpin <> -1
    long[@rxmask][port] := |< rxpin
  if txpin <> -1
    long[@txmask][port] := |< txpin

  long[@rxtx_mode][port] := mode
  'if mode & INVERTRX
  '  byte[@rxchar][port] := $ff
  long[@bit_ticks][port] := (clkfreq / baudrate)
  long[@bit4_ticks][port] := long[@bit_ticks][port] >> 2

  result := @buffers
PUB Start
'' Call start to start cog
'' Start serial driver - starts a cog
'' returns false if no cog available
''
'' tx buffers will start within the object footprint, overlaying certain locations that were initialized in spin
'' for  use within the cog but are not needed by spin thereafter and are not needed for object restart.
  '
  txbuff_tail_ptr := txbuff_ptr  := @buffers                 ' (TTA) all buffers are calculated as offsets from this address.
  txbuff_tail_ptr1 := txbuff_ptr1 := txbuff_ptr + txsize      'base addresses of the corresponding port buffer.
  txbuff_tail_ptr2 := txbuff_ptr2 := txbuff_ptr1 + txsize1
  txbuff_tail_ptr3 := txbuff_ptr3 := txbuff_ptr2 + txsize2
  rxbuff_head_ptr := rxbuff_ptr  := txbuff_ptr3 + txsize3     ' rx buffers follow immediately after the tx buffers, by size
  rxbuff_head_ptr1 := rxbuff_ptr1 := rxbuff_ptr + rxsize
  rxbuff_head_ptr2 := rxbuff_ptr2 :=  rxbuff_ptr1 + rxsize1
  rxbuff_head_ptr3 := rxbuff_ptr3 :=  rxbuff_ptr2 + rxsize2
                                                        ' note that txbuff_ptr ... rxbuff_ptr3 are the base addresses fixed
                                                        ' in memory for use by both spin and pasm
                                                        ' while txbuff_tail_ptr ... rxbuff_head_ptr3 are dynamic addresses used only by pasm
                                                        ' and here initialized to point to the start of the buffers.
                                                             ' the rx buffer #3 comes last, up through address @endfill
  rx_head_ptr  := @rx_head                              ' (TTA) note: addresses of the head and tail counts are passed to the cog
  rx_head_ptr1 := @rx_head1                             ' if that is confusing, take heart.   These are pointers to pointers to pointers
  rx_head_ptr2 := @rx_head2
  rx_head_ptr3 := @rx_head3
  rx_tail_ptr  := @rx_tail
  rx_tail_ptr1 := @rx_tail1
  rx_tail_ptr2 := @rx_tail2
  rx_tail_ptr3 := @rx_tail3
  tx_head_ptr  := @tx_head
  tx_head_ptr1 := @tx_head1
  tx_head_ptr2 := @tx_head2
  tx_head_ptr3 := @tx_head3
  tx_tail_ptr  := @tx_tail
  tx_tail_ptr1 := @tx_tail1
  tx_tail_ptr2 := @tx_tail2
  tx_tail_ptr3 := @tx_tail3
  result := cog := cognew(@entry, @rx_head) + 1

  debugLock := locknew
  result := @after

PUB Stop
'' Stop serial driver - frees a cog
  if cog
    cogstop(cog~ - 1)

PUB GetCogID : result
  return cog -1

PUB Rxflush(port)
'' Flush receive buffer, here until empty.
  repeat while rxcheck(port) => 0

PUB Txs(port, txbyte)

  DebugCog
  if txbyte <> 13
    Tx(port, txbyte)

PUB Txe(port, txbyte)

  Tx(port, txbyte)
  lockclr(debugLock)

PUB Txse(port, txbyte)

  txs(port, txbyte)
  lockclr(debugLock)

PUB Lock
'' set lock without sending cog ID

  repeat while lockset(debugLock)

PUB LockCog
'' display cog ID at the beginning of debug statements

  Lock
  Tx(0, "(")
  dec(0, cogid)
  Tx(0, ")")

PUB DebugCog
'' display cog ID at the beginning of debug statements

  Lock
  Tx(0, 11)
  Tx(0, 13)
  dec(0, cogid)
  Tx(0, ":")
  Tx(0, 32)

PUB E

  lockclr(debugLock)

PUB Strs(port, stringptr)

  DebugCog
  Str(port, stringptr)

PUB Stre(port, stringptr)

  Str(port, stringptr)
  E

PUB Strse(port, stringptr)

  Strs(port, stringptr)
  E

PUB Dece(port, value)

  Dec(port, value)
  E

PUB RxHowFull(port)    ' (TTA) added method
'' returns number of chars in rx buffer

  return ((rx_head[port] - rx_tail[port]) + rxsize[port]) // rxsize[port]
'   rx_head and rx_tail are values in the range 0=< ... < RX_BUFSIZE

PUB RxPeek(port) : rxbyte
'' Similar to RxCheck but this method does not
'' advance the buffer's tail.
'' The rx buffer is not changed by calling this method.

  rxbyte--
  if rx_tail[port] <> rx_head[port]
    rxbyte := rxchar[port] ^ byte[rxbuff_ptr[port] + rx_tail[port]]

PUB Rxcheck(port) : rxbyte
'' Check if byte received (never waits)
'' returns -1 if no byte received, $00..$FF if byte
'' (TTA) simplified references

  rxbyte--
  if rx_tail[port] <> rx_head[port]
    rxbyte := rxchar[port] ^ byte[rxbuff_ptr[port]+rx_tail[port]]
    rx_tail[port] := (rx_tail[port] + 1) // rxsize[port]

PUB Rxtime(port,ms) : rxbyte | t
'' Wait ms milliseconds for a byte to be received
'' returns -1 if no byte received, $00..$FF if byte
  t := cnt
  repeat until (rxbyte := rxcheck(port)) => 0 or (cnt - t) / (clkfreq / 1000) > ms

PUB Rx(port) : rxbyte
'' Receive byte (may wait for byte)
'' returns $00..$FF

  repeat while (rxbyte := rxcheck(port)) < 0

PUB Tx(port, txbyte)
'' Send byte (may wait for room in buffer)

  repeat until (tx_tail[port] <> (tx_head[port] + 1) // txsize[port])
  byte[txbuff_ptr[port]+tx_head[port]] := txbyte
  tx_head[port] := (tx_head[port] + 1) // txsize[port]

  if rxtx_mode[port] & 8 'NOECHO
    rx(port)

PUB TxHowFull(port)    ' (DWD) added method
'' returns number of chars in rx buffer

  return ((tx_head[port] - tx_tail[port]) + txsize[port]) // txsize[port]
'   tx_head and tx_tail are values in the range 0=< ... < TX_BUFSIZE

{
PUB Txflush(port)

  port := VirtualToPhysical(port)
  repeat until (long[@tx_tail][port] == long[@tx_head][port])
}
PUB Str(port, stringptr)
'' Send zstring
  strn(port, stringptr, strsize(stringptr))

PUB Strn(port, stringptr, nchar)
'' Send counted string

  repeat nchar
    tx(port, byte[stringptr++])

PUB Dec(port, value) | i
'' Print a decimal number

  decl(port, value, 10, 0)

PUB Decf(port, value, width) | i
'' Prints signed decimal value in space-padded, fixed-width field
  decl(port, value, width, 1)

{
PUB Decx(port,value, digits) | i
'' Prints zero-padded, signed-decimal string
'' -- if value is negative, field width is digits+1
  decl(port,value,digits,2)
}
PUB Decl(port, value, digits, flag) | i, x
'' DWD Fixed with FDX 1.2 code

  digits := 1 #> digits <# 10

  x := value == negx                                                            'Check for max negative
  if value < 0
    value := || (value + x)                                                        'If negative, make positive; adjust for max negative
    tx(port, "-")                                                                     'and output sign

  i := 1_000_000_000
  if flag & 3
    if digits < 10                                      ' less than 10 digits?
      repeat (10 - digits)                              '   yes, adjust divisor
        i /= 10

  repeat digits
    if value => i
      tx(port, value / i + "0" + x * (i == 1))
      value //= i
      result~~
    elseif (i == 1) or result or (flag & 2)
      tx(port, "0")
    elseif flag & 1
      tx(port, " ")
    i /= 10

PUB Hex(port, value, digits)
'' Print a hexadecimal number
  value <<= (8 - digits) << 2
  repeat digits
    tx(port, lookupz((value <-= 4) & $F : "0".."9", "A".."F"))

DAT

debugLock               long -1

DAT
'***********************************
'* Assembly language serial driver *
'***********************************
'
                        org 0
'
' Entry
'
'To maximize the speed of rx and tx processing, all the mode checks are no longer inline
'The initialization code checks the modes and modifies the rx/tx code for that mode
'e.g. the if condition for rx checking for a start bit will be inverted if mode INVERTRX
'is it, similar for other mode flags
'The code is also patched depending on whether a cts or rts pin are supplied. The normal
' routines support cts/rts processing. If the cts/rts mask is 0, then the code is patched
'to remove the addtional code. This means I/O modes and CTS/RTS handling adds no extra code
'in the rx/tx routines which not required.
'Similar with the co-routine variables. If a rx or tx pin is not configured the co-routine
'variable for the routine that handles that pin is modified so the routine is never called
'We start with port 3 and work down to ports because we will be updating the co-routine pointers
'and the order matters. e.g. we can update txcode3 and then update rxcode3 based on txcode3.
'(TTA): coroutine patch was not working in the way originally described.   (TTA) patched
'unused coroutines jmprets become simple jmps.
' Tim's comments about the order from 3 to 0 no longer apply.

' The following 8 locations are skipped at entry due to if_never.
' The mov instruction and the destination address are here only for syntax.
' the important thing are the source field
' primed to contain the start address of each port routine.
' When jmpret instructions are executed, the source adresses here are used for jumps
' And new source addresses will be written in the process.
entry
rxcode  if_never        mov     rxcode,#receive       ' set source fields to initial entry points
txcode  if_never        mov     txcode,#transmit
rxcode1 if_never        mov     rxcode1,#receive1
txcode1 if_never        mov     txcode1,#transmit1
rxcode2 if_never        mov     rxcode2,#receive2
txcode2 if_never        mov     txcode2,#transmit2
rxcode3 if_never        mov     rxcode3,#receive3
txcode3 if_never        mov     txcode3,#transmit3

' INITIALIZATIONS ==============================================================================
' port 3 initialization -------------------------------------------------------------
                        test    rxtx_mode3,#4 wz{OCTX}    'init tx pin according to mode
                        'test    rxtx_mode3,#INVERTTX wc
        if_z_ne_c or            outa,txmask3
        if_z            or      dira,txmask3
                                                      'patch tx routine depending on invert and oc
                                                      'if invert change muxc to muxnc
                                                      'if oc change outa to dira
        if_z_eq_c or            txout3,domuxnc        'patch muxc to muxnc
        if_nz           movd    txout3,#dira          'change destination from outa to dira
                                                      'patch rx wait for start bit depending on invert
                        test    rxtx_mode3,#1 wz{INVERTRX}  'wait for start bit on rx pin
        if_nz           xor     start3,doifc2ifnc     'if_c jmp to if_nc
                                                      'patch tx routine depending on whether cts is used
                                                      'and if it is inverted
                        or      ctsmask3,#0     wz    'cts pin? z not set if in use
        'if_nz           test    rxtx_mode3,#INVERTCTS wc 'c set if inverted
        if_nz_and_c     or      ctsi3,doif_z_or_nc    'if_nc jmp   (TTA) reversed order to correctly invert CTS
        if_nz_and_nc    or      ctsi3,doif_z_or_c     'if_c jmp
                                                      'if not cts remove the test by moving
                                                      'the transmit entry point down 1 instruction
                                                      'and moving the jmpret over the cts test
                                                      'and changing co-routine entry point
        if_z            mov     txcts3,transmit3      'copy the jmpret over the cts test
        if_z            movs    ctsi3,#txcts3         'patch the jmps to transmit to txcts0
        if_z            add     txcode3,#1            'change co-routine entry to skip first jmpret
                                                      'patch rx routine depending on whether rts is used
                                                      'and if it is inverted
                        or      rtsmask3,#0     wz
        if_nz           or      dira,rtsmask3          ' (TTA) rts needs to be an output
        if_nz           test    rxtx_mode3,#32 wc'INVERTRTS
        if_nz_and_nc    or      rts3,domuxnc          'patch muxc to muxnc
        if_z            mov     norts3,rec3i          'patch rts code to a jmp #receive3
        if_z            movs    start3,#receive3      'skip all rts processing

                        or      txmask3,#0      wz       'if tx pin not used
        if_z            movi    transmit3, #%010111_000  ' patch it out entirely by making the jmpret into a jmp (TTA)
                        or      rxmask3,#0      wz       'ditto for rx routine
        if_z            movi    receive3, #%010111_000   ' (TTA)
                                                         ' in pcFullDuplexSerial4fc, the bypass was ostensibly done
                                                         ' by patching the co-routine variables,
                                                         ' but it was commented out, and didn't work when restored
                                                         ' so I did it by changing the affected jmpret to jmp.
                                                         ' Now the jitter is MUCH reduced.
' port 2 initialization -------------------------------------------------------------
                        test    rxtx_mode2,#4 wz{OCTX}    'init tx pin according to mode
                        'test    rxtx_mode2,#INVERTTX wc
        if_z_ne_c       or      outa,txmask2
        if_z            or      dira,txmask2
        if_z_eq_c       or      txout2,domuxnc        'patch muxc to muxnc
        if_nz           movd    txout2,#dira          'change destination from outa to dira
                        test    rxtx_mode2,#1 wz{INVERTRX}  'wait for start bit on rx pin
        if_nz           xor     start2,doifc2ifnc     'if_c jmp to if_nc
                        or      ctsmask2,#0     wz
        if_nz           test    rxtx_mode2,#16 wc'INVERTCTS
        if_nz_and_c     or      ctsi2,doif_z_or_nc    'if_nc jmp   (TTA) reversed order to correctly invert CTS
        if_nz_and_nc    or      ctsi2,doif_z_or_c     'if_c jmp
       if_z            mov     txcts2,transmit2      'copy the jmpret over the cts test
        if_z            movs    ctsi2,#txcts2         'patch the jmps to transmit to txcts0
        if_z            add     txcode2,#1            'change co-routine entry to skip first jmpret
                        or      rtsmask2,#0     wz
        if_nz           or      dira,rtsmask2          ' (TTA) rts needs to be an output
        if_nz           test    rxtx_mode2,#32 wc'INVERTRTS wc
        'if_nz_and_nc    or      rts2,domuxnc          'patch muxc to muxnc
        if_z            mov     norts2,rec2i          'patch to a jmp #receive2
        if_z            movs    start2,#receive2      'skip all rts processing

                                or txmask2,#0    wz       'if tx pin not used
        if_z            movi    transmit2, #%010111_000   ' patch it out entirely by making the jmpret into a jmp (TTA)
                        or      rxmask2,#0      wz        'ditto for rx routine
        if_z            movi    receive2, #%010111_000    ' (TTA)

' port 1 initialization -------------------------------------------------------------
                        test    rxtx_mode1,#4 wz{OCTX}    'init tx pin according to mode
                        'test    rxtx_mode1,#INVERTTX wc
        if_z_ne_c       or      outa,txmask1
        if_z            or      dira,txmask1
        if_z_eq_c       or      txout1,domuxnc        'patch muxc to muxnc
        if_nz           movd    txout1,#dira          'change destination from outa to dira
                        test    rxtx_mode1,#1{INVERTRX} wz 'wait for start bit on rx pin
        if_nz           xor     start1,doifc2ifnc     'if_c jmp to if_nc
                        or      ctsmask1,#0     wz
        if_nz           test    rxtx_mode1,#16 wc'INVERTCTS

        if_z            add     txcode1,#1            'change co-routine entry to skip first jmpret
                                                      'patch rx routine depending on whether rts is used
                                                      'and if it is inverted

        if_z            mov     norts1,rec1i          'patch to a jmp #receive1
        if_z            movs    start1,#receive1      'skip all rts processing

                        or      txmask1,#0      wz       'if tx pin not used
        if_z            movi    transmit1, #%010111_000  ' patch it out entirely by making the jmpret into a jmp (TTA)
                        or      rxmask1,#0      wz       'ditto for rx routine
        if_z            movi    receive1, #%010111_000   ' (TTA)

' port 0 initialization -------------------------------------------------------------
                        test    rxtx_mode,#4 wz{OCTX}     'init tx pin according to mode
                        'test    rxtx_mode,#INVERTTX wc
        if_z_ne_c       or      outa,txmask
        if_z            or      dira,txmask
                                                      'patch tx routine depending on invert and oc
                                                      'if invert change muxc to muxnc
                                                      'if oc change out1 to dira
        if_z_eq_c       or      txout0,domuxnc        'patch muxc to muxnc
        if_nz           movd    txout0,#dira          'change destination from outa to dira
                                                      'patch rx wait for start bit depending on invert
                        test    rxtx_mode,#1 wz{INVERTRX}   'wait for start bit on rx pin
        if_nz           xor     start0,doifc2ifnc     'if_c jmp to if_nc
                                                      'patch tx routine depending on whether cts is used
                                                      'and if it is inverted
                        or      ctsmask,#0     wz     'cts pin? z not set if in use
        'if_nz           or      dira,rtsmask          ' (TTA) rts needs to be an output
        'if_nz           test    rxtx_mode,#INVERTCTS wc 'c set if inverted
        if_nz_and_c     or      ctsi0,doif_z_or_nc    'if_nc jmp   (TTA) reversed order to correctly invert CTS
        if_nz_and_nc    or      ctsi0,doif_z_or_c     'if_c jmp
        if_z            mov     txcts0,transmit       'copy the jmpret over the cts test
        if_z            movs    ctsi0,#txcts0         'patch the jmps to transmit to txcts0
        if_z            add     txcode,#1             'change co-routine entry to skip first jmpret
                                                      'patch rx routine depending on whether rts is used
                                                      'and if it is inverted
       '                 or      rtsmask,#0     wz     'rts pin, z not set if in use
        'if_nz           test    rxtx_mode,#INVERTRTS wc
        'if_nz_and_nc    or      rts0,domuxnc          'patch muxc to muxnc
        if_z            mov     norts0,rec0i          'patch to a jmp #receive
        if_z            movs    start0,#receive       'skip all rts processing if not used

                        or      txmask,#0      wz       'if tx pin not used
        if_z            movi    transmit, #%010111_000  ' patch it out entirely by making the jmpret into a jmp (TTA)
                        or      rxmask,#0      wz       'ditto for rx routine
        if_z            movi    receive, #%010111_000   ' (TTA)
'
' MAIN LOOP  =======================================================================================
' Receive0 -------------------------------------------------------------------------------------
receive                 jmpret  rxcode,txcode         'run a chunk of transmit code, then return
                                                      'patched to a jmp if pin not used
                        test    rxmask,ina      wc
start0  if_c            jmp     #norts0               'go check rts if no start bit
                                                      ' have to check rts because other process may remove chars
                                                      'will be patched to jmp #receive if no rts

                        mov     rxbits,#9             'ready to receive byte
                        mov     rxcnt,bit4_ticks      '1/4 bits
                        add     rxcnt,cnt

:bit                    add     rxcnt,bit_ticks       '1 bit period

:wait                   jmpret  rxcode,txcode         'run a chuck of transmit code, then return

                        mov     t1,rxcnt              'check if bit receive period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait

                        test    rxmask,ina      wc    'receive bit on rx pin
                        rcr     rxdata,#1
                        djnz    rxbits,#:bit          'get remaining bits
                        test    rxtx_mode,#1 wz{INVERTRX}        'find out if rx is inverted
        if_z_ne_c       jmp     #receive              'abort if no stop bit   (TTA) (from serialMirror)
                        jmpret  rxcode,txcode         'run a chunk of transmit code, then return

                        shr     rxdata,#32-9          'justify and trim received byte

                        wrbyte  rxdata,rxbuff_head_ptr'{7-22} '1wr
                        add     rx_head,#1
                        cmpsub  rx_head,rxsize   ' (TTA) allows non-binary buffer size
                        wrlong  rx_head,rx_head_ptr   '{8}     '2wr
                        mov     rxbuff_head_ptr,rxbuff_ptr 'calculate next byte head_ptr
                        add     rxbuff_head_ptr,rx_head
norts0                  rdlong  rx_tail,rx_tail_ptr   '{7-22 or 8} will be patched to jmp #r3 if no rts
                                                                '1rd
                        mov     t1,rx_head
                        sub     t1,rx_tail  wc          'calculate number bytes in buffer, (TTA) add wc
'                        and     t1,#$7F               'fix wrap
        if_c            add     t1,rxsize           ' fix wrap, (TTA) change
                        cmps    t1,rtssize      wc    'is it more than the threshold
rts0                    muxc    outa,rtsmask          'set rts correctly

rec0i                   jmp     #receive              'byte done, receive next byte
'
' Receive1 -------------------------------------------------------------------------------------
'
receive1                jmpret  rxcode1,txcode1       'run a chunk of transmit code, then return

                        test    rxmask1,ina     wc
start1  if_c            jmp     #norts1               'go check rts if no start bit

                        mov     rxbits1,#10 '** 9            'ready to receive byte
                        mov     rxcnt1,bit4_ticks1    '1/4 bits
                        add     rxcnt1,cnt

:bit1                   add     rxcnt1,bit_ticks1     '1 bit period

:wait1                  jmpret  rxcode1,txcode1       'run a chuck of transmit code, then return

                        mov     t1,rxcnt1             'check if bit receive period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait1

                        test    rxmask1,ina     wc    'receive bit on rx pin
                        rcr     rxdata1,#1
                        djnz    rxbits1,#:bit1

                        test    rxtx_mode1,#1 wz{INVERTRX}        'find out if rx is inverted
        if_z_ne_c       jmp     #receive1              'abort if no stop bit   (TTA) (from serialMirror)

                        jmpret  rxcode1,txcode1       'run a chunk of transmit code, then return
                        shr     rxdata1,#32-9         'justify and trim received byte

                        wrbyte  rxdata1,rxbuff_head_ptr1 '7-22
                        add     rx_head1,#1
                        cmpsub  rx_head1,rxsize1         ' (TTA) allows non-binary buffer size
                        wrlong  rx_head1,rx_head_ptr1
                        mov     rxbuff_head_ptr1,rxbuff_ptr1 'calculate next byte head_ptr
                        add     rxbuff_head_ptr1,rx_head1
norts1                  rdlong  rx_tail1,rx_tail_ptr1    '7-22 or 8 will be patched to jmp #r3 if no rts
                        mov     t1,rx_head1
                        sub     t1,rx_tail1    wc
        if_c            add     t1,rxsize1           ' fix wrap, (TTA) change
                        cmps    t1,rtssize1     wc
rts1                    muxc    outa,rtsmask1

rec1i                   jmp     #receive1             'byte done, receive next byte
' Receive2 -------------------------------------------------------------------------------------
'
receive2                jmpret  rxcode2,txcode2       'run a chunk of transmit code, then return

                        test    rxmask2,ina     wc
start2 if_c             jmp     #norts2               'go check rts if no start bit

                        mov     rxbits2,#9            'ready to receive byte
                        mov     rxcnt2,bit4_ticks2    '1/4 bits
                        add     rxcnt2,cnt

:bit2                   add     rxcnt2,bit_ticks2     '1 bit period

:wait2                  jmpret  rxcode2,txcode2       'run a chuck of transmit code, then return

                        mov     t1,rxcnt2             'check if bit receive period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait2

                        test    rxmask2,ina     wc    'receive bit on rx pin
                        rcr     rxdata2,#1
                        djnz    rxbits2,#:bit2
                        test    rxtx_mode2,#1 wz{INVERTRX}        'find out if rx is inverted
        if_z_ne_c       jmp     #receive2              'abort if no stop bit   (TTA) (from serialMirror)

                        jmpret  rxcode2,txcode2       'run a chunk of transmit code, then return
                        shr     rxdata2,#32-9         'justify and trim received byte

                        wrbyte  rxdata2,rxbuff_head_ptr2 '7-22
                        add     rx_head2,#1
                        cmpsub  rx_head2,rxsize2        '  ' (TTA) allows non-binary buffer size
                        wrlong  rx_head2,rx_head_ptr2
                        mov     rxbuff_head_ptr2,rxbuff_ptr2 'calculate next byte head_ptr
                        add     rxbuff_head_ptr2,rx_head2
norts2                  rdlong  rx_tail2,rx_tail_ptr2    '7-22 or 8 will be patched to jmp #r3 if no rts
                        mov     t1,rx_head2
                        sub     t1,rx_tail2    wc
        if_c            add     t1,rxsize2            ' fix wrap, (TTA) change
                        cmps    t1,rtssize2     wc
rts2                    muxc    outa,rtsmask2

rec2i                   jmp     #receive2             'byte done, receive next byte
'
' Receive3 -------------------------------------------------------------------------------------
'
receive3                jmpret  rxcode3,txcode3       'run a chunk of transmit code, then return

                        test    rxmask3,ina     wc
start3 if_c             jmp     #norts3               'go check rts if no start bit

                        mov     rxbits3,#9            'ready to receive byte
                        mov     rxcnt3,bit4_ticks3    '1/4 bits
                        add     rxcnt3,cnt

:bit3                   add     rxcnt3,bit_ticks3     '1 bit period

:wait3                  jmpret  rxcode3,txcode3       'run a chuck of transmit code, then return

                        mov     t1,rxcnt3             'check if bit receive period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait3

                        test    rxmask3,ina     wc    'receive bit on rx pin
                        rcr     rxdata3,#1
                        djnz    rxbits3,#:bit3
                        test    rxtx_mode3,#1 wz {INVERTRX}       'find out if rx is inverted
        if_z_ne_c       jmp     #receive3              'abort if no stop bit   (TTA) (from serialMirror)

                        jmpret  rxcode3,txcode3       'run a chunk of transmit code, then return
                        shr     rxdata3,#32-9         'justify and trim received byte

                        wrbyte  rxdata3,rxbuff_head_ptr3 '7-22
                        add     rx_head3,#1
                        cmpsub  rx_head3,rxsize3         ' (TTA) allows non-binary buffer size
                        wrlong  rx_head3,rx_head_ptr3    '8
                        mov     rxbuff_head_ptr3,rxbuff_ptr3 'calculate next byte head_ptr
                        add     rxbuff_head_ptr3,rx_head3
norts3                  rdlong  rx_tail3,rx_tail_ptr3    '7-22 or 8, may be patched to jmp #r3 if no rts
                        mov     t1,rx_head3
                        sub     t1,rx_tail3    wc
        if_c            add     t1,rxsize3            ' fix wrap, (TTA) change
                        cmps    t1,rtssize3     wc    'is buffer more that 3/4 full?
rts3                    muxc    outa,rtsmask3

rec3i                   jmp     #receive3             'byte done, receive next byte
'
' TRANSMIT =======================================================================================
'
transmit                jmpret  txcode,rxcode1        'run a chunk of receive code, then return
                                                      'patched to a jmp if pin not used

txcts0                  test    ctsmask,ina     wc    'if flow-controlled dont send
                        rdlong  t1,tx_head_ptr        '{7-22} - head[0]
                        cmp     t1,tx_tail      wz    'tail[0]
ctsi0   if_z            jmp     #transmit             'may be patched to if_z_or_c or if_z_or_nc

                        rdbyte  txdata,txbuff_tail_ptr '{8}
                        add     tx_tail,#1
                        cmpsub     tx_tail,txsize    wz   ' (TTA) for individually sized buffers, will zero at rollover
                        wrlong  tx_tail,tx_tail_ptr    '{8}
        if_z            mov     txbuff_tail_ptr,txbuff_ptr 'reset tail_ptr if we wrapped
        if_nz           add     txbuff_tail_ptr,#1    'otherwise add 1

                        jmpret  txcode,rxcode1

                        shl     txdata,#2
                        or      txdata,txbitor        'ready byte to transmit
                        mov     txbits,#11
                        mov     txcnt,cnt

txbit                   shr     txdata,#1       wc
txout0                  muxc    outa,txmask           'maybe patched to muxnc dira,txmask
                        add     txcnt,bit_ticks       'ready next cnt

:wait                   jmpret  txcode,rxcode1        'run a chunk of receive code, then return

                        mov     t1,txcnt              'check if bit transmit period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait

                        djnz    txbits,#txbit         'another bit to transmit?
txjmp0                  jmp     ctsi0                 'byte done, transmit next byte
'
' Transmit1 -------------------------------------------------------------------------------------
'
transmit1               jmpret  txcode1,rxcode2       'run a chunk of receive code, then return

txcts1                  test    ctsmask1,ina    wc    'if flow-controlled dont send
                        rdlong  t1,tx_head_ptr1
                        cmp     t1,tx_tail1     wz
ctsi1   if_z            jmp     #transmit1            'may be patched to if_z_or_c or if_z_or_nc

                        rdbyte  txdata1,txbuff_tail_ptr1
                        add     tx_tail1,#1
                        cmpsub     tx_tail1,txsize1   wz   ' (TTA) for individually sized buffers, will zero at rollover
                        wrlong  tx_tail1,tx_tail_ptr1
        if_z            mov     txbuff_tail_ptr1,txbuff_ptr1 'reset tail_ptr if we wrapped
        if_nz           add     txbuff_tail_ptr1,#1   'otherwise add 1

                        jmpret  txcode1,rxcode2       'run a chunk of receive code, then return
            ''**
                        shl     txdata1,#2
                        or      txdata1,txbitor wc

                        mov     txbits1,#11
                        mov     txcnt1,cnt

txbit1                  shr     txdata1,#1      wc
txout1                  muxc    outa,txmask1          'maybe patched to muxnc dira,txmask
                        add     txcnt1,bit_ticks1     'ready next cnt

:wait1                  jmpret  txcode1,rxcode2       'run a chunk of receive code, then return

                        mov     t1,txcnt1             'check if bit transmit period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait1

                        djnz    txbits1,#txbit1       'another bit to transmit?
txjmp1                  jmp     ctsi1                 'byte done, transmit next byte
' Transmit2 -------------------------------------------------------------------------------------
'
transmit2               jmpret  txcode2,rxcode3       'run a chunk of receive code, then return

txcts2                  test    ctsmask2,ina    wc    'if flow-controlled dont send
                        rdlong  t1,tx_head_ptr2
                        cmp     t1,tx_tail2     wz
ctsi2   if_z            jmp     #transmit2            'may be patched to if_z_or_c or if_z_or_nc

                        rdbyte  txdata2,txbuff_tail_ptr2
                        add     tx_tail2,#1
                        cmpsub     tx_tail2,txsize2   wz   ' (TTA) for individually sized buffers, will zero at rollover
                        wrlong  tx_tail2,tx_tail_ptr2
        if_z            mov     txbuff_tail_ptr2,txbuff_ptr2 'reset tail_ptr if we wrapped
        if_nz           add     txbuff_tail_ptr2,#1   'otherwise add 1

                        jmpret  txcode2,rxcode3

                        shl     txdata2,#2
                        or      txdata2,txbitor       'ready byte to transmit
                        mov     txbits2,#11
                        mov     txcnt2,cnt

txbit2                  shr     txdata2,#1      wc
txout2                  muxc    outa,txmask2          'maybe patched to muxnc dira,txmask
                        add     txcnt2,bit_ticks2     'ready next cnt

:wait2                  jmpret  txcode2,rxcode3       'run a chunk of receive code, then return

                        mov     t1,txcnt2             'check if bit transmit period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait2

                        djnz    txbits2,#txbit2       'another bit to transmit?
txjmp2                  jmp     ctsi2                 'byte done, transmit next byte
'
' Transmit3 -------------------------------------------------------------------------------------
'
transmit3               jmpret  txcode3,rxcode        'run a chunk of receive code, then return

txcts3                  test    ctsmask3,ina    wc    'if flow-controlled dont send
                        rdlong  t1,tx_head_ptr3
                        cmp     t1,tx_tail3     wz
ctsi3   if_z            jmp     #transmit3            'may be patched to if_z_or_c or if_z_or_nc

                        rdbyte  txdata3,txbuff_tail_ptr3
                        add     tx_tail3,#1
                        cmpsub     tx_tail3,txsize3   wz   ' (TTA) for individually sized buffers, will zero at rollover
                        wrlong  tx_tail3,tx_tail_ptr3
        if_z            mov     txbuff_tail_ptr3,txbuff_ptr3 'reset tail_ptr if we wrapped
        if_nz           add     txbuff_tail_ptr3,#1   'otherwise add 1

                        jmpret  txcode3,rxcode

                        shl     txdata3,#2
                        or      txdata3,txbitor       'ready byte to transmit
                        mov     txbits3,#11
                        mov     txcnt3,cnt

txbit3                  shr     txdata3,#1      wc
txout3                  muxc    outa,txmask3          'maybe patched to muxnc dira,txmask
                        add     txcnt3,bit_ticks3     'ready next cnt

:wait3                  jmpret  txcode3,rxcode        'run a chunk of receive code, then return

                        mov     t1,txcnt3             'check if bit transmit period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait3

                        djnz    txbits3,#txbit3       'another bit to transmit?
txjmp3                  jmp     ctsi3                 'byte done, transmit next byte
'
'The following are constants used by pasm for patching the code, depending on options required
doifc2ifnc              long      $003c0000           'patch condition if_c to if_nc using xor
doif_z_or_c             long      $00380000           'patch condition if_z to if_z_or_c using or
doif_z_or_nc            long      $002c0000           'patch condition if_z to if_z_or_nc using or
domuxnc                 long      $04000000           'patch muxc to muxnc using or
txbitor                 long      $0401               'bits to or for transmitting, adding start and stop bits

' Buffer sizes initialized from CONstants and used by both spin and pasm

rxsize                  long      RX_SIZE0                  ' (TTA) size of the rx and tx buffers is available to pasm and spin
rxsize1                 long      RX_SIZE1                  ' these values are transfered from the declared CONstants
rxsize2                 long      RX_SIZE2                  ' at startup, individually configurable
rxsize3                 long      RX_SIZE3
txsize                  long      TX_SIZE0
txsize1                 long      TX_SIZE1
txsize2                 long      TX_SIZE2
txsize3                 long      TX_SIZE3


' Object memory from here to the end is zeroed in the init/stop method ---------------'
' Some locations within the next set of values, after being initialized to zero, are then filled with alternative options
' That are accessed from both spin and pasm
' Dont Change the order of these initialized variables within port groups of 4 without modifying
' the code to match - both spin and assembler

startfill
rxchar                byte      0             ' used by spin rxcheck, for inversion of received data
rxchar1               byte      0
rxchar2               byte      0
rxchar3               byte      0
cog                   long      0                   'cog flag/id
rxtx_mode             long      0             ' mode setting from values passed in by addport
rxtx_mode1            long      0             '
rxtx_mode2            long      0
rxtx_mode3            long      0
rx_head               long      0             ' rx head pointer, from 0 to size of rx buffer, used in spin and pasm
rx_head1              long      0             ' data is enqueued to this offset above base, rxbuff_ptr
rx_head2              long      0
rx_head3              long      0
rx_tail               long      0             ' rx tail pointer, ditto, zero to size of rx buffer
rx_tail1              long      0             ' data is dequeued from this offset above base, rxbuff_ptr
rx_tail2              long      0
rx_tail3              long      0
tx_head               long      0             ' tx head pointer, , from 0 to size of tx buffer, used in spin and pasm
tx_head1              long      0             ' data is enqueued to this offset above base, txbuff_ptr
tx_head2              long      0
tx_head3              long      0
tx_tail               long      0             ' tx tail pointer, ditto, zero to size of rx buffer
tx_tail1              long      0             ' data is transmitted from this offset above base, txbuff_ptr
tx_tail2              long      0
tx_tail3              long      0
rxbuff_ptr            long      0             ' These are the base hub addresses of the receive buffers
rxbuff_ptr1           long      0             ' initialized in spin, referenced in pasm and spin
rxbuff_ptr2           long      0             ' these buffers and sizes are individually configurable
rxbuff_ptr3           long      0
txbuff_ptr            long      0             ' These are the base hub addresses of the transmit buffers
txbuff_ptr1           long      0
txbuff_ptr2           long      0
txbuff_ptr3           long      0

'  Start of HUB overlay ------------------------------------------------------------------------
' Some locations within the next set of values, after being init'd to zero, are then filled from spin with options
' That are transferred to and accessed by the pasm cog once started, but no longer needed in spin.
' Therefore, tx and rx buffers start here and overlays the hub footprint of these variables.
' tx_buffers come first, 0,1,2,3, then rx buffers 0,1,2,3 by offset from "buffers"
overlay
buffers
txdata                long      0
txbits                long      0
txcnt                 long      0
txdata1               long      0
txbits1               long      0
txcnt1                long      0
txdata2               long      0
txbits2               long      0
txcnt2                long      0
txdata3               long      0
txbits3               long      0
txcnt3                long      0
rxdata                long      0
rxbits                long      0
rxcnt                 long      0
rxdata1               long      0
rxbits1               long      0
rxcnt1                long      0
rxdata2               long      0
rxbits2               long      0
rxcnt2                long      0
rxdata3               long      0
rxbits3               long      0
rxcnt3                long      0
t1                    long      0               ' this is a temporary variable used by pasm
rxmask                long      0               ' a single bit set, a mask for the pin used for receive, zero if port not used for receive
rxmask1               long      0
rxmask2               long      0
rxmask3               long      0
txmask                long      0               ' a single bit set, a mask for the pin used for transmit, zero if port not used for transmit
txmask1               long      0
txmask2               long      0
txmask3               long      0
ctsmask               long      0             ' a single bit set, a mask for the pin used for cts input, zero if port not using cts
ctsmask1              long      0
ctsmask2              long      0
ctsmask3              long      0
rtsmask               long      0             ' a single bit set, a mask for the pin used for rts output, zero if port not using rts
rtsmask1              long      0
rtsmask2              long      0
rtsmask3              long      0
bit4_ticks            long      0             ' bit ticks for start bit, 1/4 of standard bit
bit4_ticks1           long      0
bit4_ticks2           long      0
bit4_ticks3           long      0
bit_ticks             long      0             ' clock ticks per bit
bit_ticks1            long      0
bit_ticks2            long      0
bit_ticks3            long      0
rtssize               long      0             ' threshold in count of bytes above which will assert rts to stop flow
rtssize1              long      0
rtssize2              long      0
rtssize3              long      0
rxbuff_head_ptr         long      0             ' Hub address of data received, base plus offset
rxbuff_head_ptr1        long      0             ' pasm writes WRBYTE to hub at this address, initialized in spin to base address
rxbuff_head_ptr2        long      0
rxbuff_head_ptr3        long      0
txbuff_tail_ptr         long      0             ' Hub address of data tranmitted, base plus offset
txbuff_tail_ptr1        long      0             ' pasm reads RDBYTE from hub at this address, initialized in spin to base address
txbuff_tail_ptr2        long      0
txbuff_tail_ptr3        long      0
rx_head_ptr             long      0             ' pointer to the hub address of where the head and tail offset pointers are stored
rx_head_ptr1            long      0             ' these pointers are initialized in spin but then used only by pasm
rx_head_ptr2            long      0             ' the pasm cog has to know where in the hub to find those offsets.
rx_head_ptr3            long      0
rx_tail_ptr             long      0
rx_tail_ptr1            long      0
rx_tail_ptr2            long      0
rx_tail_ptr3            long      0
tx_head_ptr             long      0
tx_head_ptr1            long      0
tx_head_ptr2            long      0
tx_head_ptr3            long      0
tx_tail_ptr             long      0
tx_tail_ptr1            long      0
tx_tail_ptr2            long      0
tx_tail_ptr3            long      0
       '' ----------- End of the  object memory zeroed from startfill to endfill in the init/stop method ------
endfill
      FIT
'' The above is all of the necessary code that must fit in the cog
'' The following are extra bytes if necessary to provide the required rx and tx buffers.
'' the number required is computed from the aggregate buffer size declared, minus the above initialized but recycled variables.

extra                   byte    0 [RXTX_BUFSIZE - (RXTX_BUFSIZE <# (@extra - @overlay))]
after                   byte    0
DAT ''TERMS OF USE: MIT License
{{
Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify,
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}}