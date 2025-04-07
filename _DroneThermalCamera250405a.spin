DAT programName                 byte "_DroneThermalCamera250405a", 0 {Keep versions up here, last 7 CHRS}

CON 'Update Notes
{

  21a Rename _DroneThermalCamera250319a to _DroneThrermalCrsf250321a.
  240321a Start adding Crossfire protocol to program.
  21a Change UART port order to make easier to index CRSF arrays.
  21c Add code to read and display Crossfire packet data.
  21c Compiles but not tested.
  22a Change pin assignments to work with Korpi encoder board.
  22a No change needed.
  22a Outputs zeros when nothing is connected to the CRSF UART.
  22a When CRSF lines are connected the program immediately reboots.
  23a Try to fix reboot problem.
  23a Doesn't crash with all the delays I added.
  23b Reduce some four second delays to one second delays.
  23c Add flag for each input type.
  23c Test with Speedybee Bee35. Data is being received but program can't
  parse it. I'm not sure if the baud is correct.
  Pull-up resisters are likely needed on the CRSF UARTs.
  24b 115,200 bps is too slow for ELRS receiver.
  24d Try a receive only version of PST. Slow down baud.
  24d It kind of works. The correct character is not always detected.
  Try removing debug code from PASM.
  24e Works at 9600 bps. Try at 115200.
  24f It works at 115200.
  24g Works at 230400.
  24h I thought I tried 460800 but it didn'yt appear to work. I think
  I had the baud wrong.
  24i Try 250000.
  24i 250000 works!
  24j Try 460800 again.
  25a Apparently CRSF baud is 416666 bps.
  Try this baud with an ELRS receiver.
  25b Add second receive only object.
  25e All the received checksums appear to be zero. I'm likely not processing the
  data correctly.
  26a Works OK except for the Crossfire protocol.
  26b Comment out calls to read Crossfire. Comment out most debug statements.
  26b This is teh version set to Giz FPV in the UK.
  0405a Revert to _DroneThermalCamera250326b. Add additional palette options as suggested by Giz FPV.
  05a Added missing palettes.

  }
CON 'To Do
{
  250317 Add support for ELRS and Mavlink.
  Add ways to save changes to variables in this program to EEPROM.
  Save things like which RC channels control which camera parameter


}
CON                             'Constants. Set up pin assignments

  _clkmode = xtal1 + pll16x
  '_xinfreq = 6_250_000
  _xinfreq = 5_000_000

  'Below is code to figure out clock speed from registers settings.
  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq

  SECOND = CLK_FREQ

  MILLISECOND = SECOND / 1000
  MICROSECOND = MILLISECOND / 1000

  NOT_A_NUMBER = $7FFF_FFFF
CON

  CAMERA_REPLY_TIMEOUT_2S = 2 * SECOND
  CAMERA_WRITE_DELAY_250MS = 250 * MILLISECOND

  CRSF_TIMEOUT_250MS = 250 * MILLISECOND



  ' date mode enumeration
  #0, DAY_FULL_MONTH_YEAR_0, DAY_ABREV_MONTH_YEAR_1
      DELIMITED_DAY_MONTH_YEAR_2,DELIMITED_MONTH_DAY_YEAR_3
      SHORT_DAY_ABREV_MONTH_YEAR_4

  MONTH_ABREVIATION_SIZE_3 = 3

CON

  '' We will probably want to change the debug port from the USB pins.
  '' If a FTDI chip is connected to some Propeller boards without
  '' also having the USB connected, there can be problems.

  '' rx port enumeration
  #0, ELRS_CONTROL_RX_PORT_0, ELRS_TELEMETRY_RX_PORT_1

  USB_PORT_0 = 0'Need to add pass through later.

  USB_BAUD_115200 = 115200
  ELRS_BAUD_416666 = 416666 '460800 '230400 '115200 '420000 9600 '250000 '
  CAMERA_BAUD_115200 = 115200

  PARAMETER_SELECT_4 = 4
  VALUE_CYCLE_5 = 5
  PALETTE_CYCLE_6 = 6
  'PALETTE_KNOB_7 = 7


  {KNOB0_8 = 8
  KNOB1_9 = 9
  KNOB2_10 = 10
  KNOB3_11 = 11 }
  HEARTBEAT_14 = 14
  'LED_DEBUG_15 = 15


  ELRS_CONTROL_RX_16 = 16
  ELRS_TELEMETRY_RX_17 = 17
  CAMERA_TX_8 = 8
  CAMERA_RX_9 = 9


  USB_TX_30 = 30
  USB_RX_31 = 31


CON  'expectedUserInput enumeration
  #0, READY_USER_EXPECTED_0, READ_USER_EXPECTED_1, WAIT_FOR_READ_USER_EXPECTED_2
      DATA_INPUT_USER_EXPECTED_3, WRITE_USER_EXPECTED_4, WAIT_FOR_WRITE_USER_EXPECTED_5

  'targetPalette enumeration
  #0, WHITE_HOT_PALETTE_0, BLACK_HOT_PALETTE_1, FUSION1_PALETTE_2, RAINBOW_PALETTE_3
      FUSION2_PALETTE_4, IRON_RED1_PALETTE_5, IRON_RED2_PALETTE_6, DARK_BROWN_PALETTE_7
      COLOR1_PALETTE_8, COLOR2_PALETTE_9, ICE_FIRE_PALETTE_10, RAIN_PALETTE_11
      GREEN_HOT_PALETTE_12, RED_HOT_PALETTE_13, DEEP_BLUE_PALETTE_14

  MAX_PALETTE_14 = DEEP_BLUE_PALETTE_14
  NUMBER_OF_PALETTES_15 = MAX_PALETTE_14 + 1


  'mirroring enumeration
  #0, NO_MIRRORING_0, CENTRAL_MIRRORING_1, LEFT_AND_RIGHT_MIRRORING_2, UP_AND_DOWN_MIRRORING_3

  MAX_PACKET_SIZE_RX_128 = 128
  MAX_PACKET_SIZE_TX_16 = 16
  MAX_MODEL_CHARACTERS_16 = 16

  PACKET_START_0XF0 = $F0
  CAMERA_DEVICE_ADDRESS_0X36 = $36
  MODEL_CLASS_0X74 = $74
  MODEL_SUBCLASS_0X02 = $02
  PALETTE_CLASS_0X78 = $78
  PALETTE_SUBCLASS_0X20 = $20
  PACKET_END_0XFF = $FF


  'cameraDataType enumeration
  #0, NO_DATA_0, MODEL_DATA_1, FPGA_VERSION_DATA_2, FPGA_TIME_DATA_3, SOFTWARE_VERSION_DATA_4
      SOFTWARE_TIME_DATA_5, CAL_TIME_DATA_6, ISP_DATA_7, SAVE_DATA_8, RESET_DATA_9
      SHUTTER_DATA_10, BACKGROUND_DATA_11, VIGNETTING_DATA_12, AUTO_SHUTTER_DATA_13
      AUTO_INTERVAL_DATA_14, DEFECTIVE_PIXEL_DATA_15, BRIGHTNESS_DATA_16, CONTRAST_DATA_17
      ENHANCEMENT_DATA_18, STATIC_DENOISING_DATA_19, DYNAMIC_DENOISING_DATA_20
      PALETTE_DATA_21, MIRROR_DATA_22, INIT_STATE_REQUEST_DATA_23, INIT_STATE_REPLY_DATA_24

  NUMBER_OF_DATA_TYPES_25 = INIT_STATE_REPLY_DATA_24 + 1

{ Commmands
  Manual Shutter Calibration
  Manual Background Correction
  Vignetting Correction
  Automatic Shutter Control
  Defective Pixel Correction
  Cursor display
  Brightness
  Contrast
  Digital Enhancement
  Denoising
  Palette
}
  'cameraFlagRx & cameraFlagTx enumeration
  #0, WRITE_FLAG_0, READ_FLAG_1, UNUSED_2, NORMAL_FLAG_3, ERROR_FLAG_4

  'packetProgress enumeration '"packetProgress" indicates which part of the process has been completed.
  #0, NONE_PACKET_RX_0, START_PACKET_RX_1, SIZE_PACKET_RX_2, DEVICE_PACKET_RX_3, CLASS_PACKET_RX_4
     SUBCLASS_PACKET_RX_5, FLAG_PACKET_RX_6, DATA_PACKET_RX_7, CHECKSUM_PACKET_RX_8



  'cameraTxRequest
  #0, NO_CAMERA_TX_REQUEST_0, READ_CAMERA_TX_REQUEST_1, WRITE_CAMERA_TX_REQUEST_2


CON '' Note On Cog Usage
{{
  2 PASM Cogs:
  #1 Serial.


  2 Spin Cogs:
  #0 Serial Coordination Cog.


}}

OBJ

  Serial : "LedSerial250308a"                          ' uses one cog
  Camera : "Pst250317a"
  ElrsRx : "RxOnly250324a"
  Format : "StrFmt170728a"
  'Leds : "LedCog240623a"                                 ' uses one cog
  'Ws2812 : "jm_ws2812"
  Rc : "RcReceiver121116c"
  I2c : "Propeller Eeprom"



VAR

  '' Keep below together and in order

  long droneLoopCount
  long readSensorCount

  long clockChangedFlag, globalDebug
  long userInputType
  long serialMonitorCog, serialPasmCog, ledMonitorCog, ledPasmCog
  long targetPalette, rxPalette
  long expectedSizeRx, cameraClassRx, cameraSubclassRx, cameraFlagRx
  long dataRxCount, rxBufferIndex, dataTxCount, calculatedChecksum, rxChecksum, txChecksum
  long txSize, cameraClassTx, cameraSubclassTx, cameraFlagTx
  long packetProgress, pPacketProgress
  long cameraTxRequest, frozenCameraTxRequest, pCameraTxRequest
  long cameraDataType
  long cameraInputErrorCount
  long cameraReplyTimer, cameraTimeoutCount
  long completeRxCount, pCompleteRxCount
  long unexpectedPacketCount, normalFlagCount, errorFlagCount

  long expectedUserInput, pExpectedUserInput, inputNumber, activeParameterPtr
  long writeOnlyFlag
  long parameterName, minParameter, maxParameter
  long debugDelay
  long cameraCog, crsfCog[2]

  byte rxData[MAX_PACKET_SIZE_RX_128]
  byte txData[MAX_PACKET_SIZE_TX_16]

PUB Startup | portIndex, previousCount                                                  ' Serial Cog

  globalDebug := true
  previousCount := 0

  debugDelay := clkfreq
  Initialize

  Serial.Str(USB_PORT_0, string(11, 13, "Before wait."))

  Serial.Str(USB_PORT_0, string(11, 13, "MILLISECOND = "))
  Serial.Dec(USB_PORT_0, MILLISECOND)

  '' Used during development. Not used when flying in drone.

  WaitForUser

  Serial.Str(USB_PORT_0, string(11, 13, "Before flush."))
  Serial.RxFlush(USB_PORT_0)
  Serial.Str(USB_PORT_0, string(11, 13, "After flush."))
  Serial.Str(USB_PORT_0, string(11, 13, "programName = "))
  Serial.Str(USB_PORT_0, @programName)

  serialMonitorCog := cogId

  Serial.Str(USB_PORT_0, string(11, 13, "serialMonitorCog = "))
  Serial.Dec(USB_PORT_0, serialMonitorCog)
  Serial.Str(USB_PORT_0, string(11, 13, "rcCog = "))
  Serial.Dec(USB_PORT_0, rcCog)

  MainLoop


PUB WaitForUser | localRcDifference

  Serial.Str(USB_PORT_0, string(11, 13, "WaitForUser"))


  repeat

    waitcnt(clkfreq / 2 + cnt)
    if checkUserUartFlag
      Serial.Str(USB_PORT_0, string(11, 13, "Any key to start."))

    if checkRcFlag
      incrementPulse := Rc.Get(0)
      localRcDifference := pIncrementPulse - incrementPulse
      Serial.Str(USB_PORT_0, string(11, 13, "localRcDifference was = "))
      Serial.Dec(USB_PORT_0, localRcDifference)
      ||localRcDifference
      pIncrementPulse := incrementPulse

      Serial.Str(USB_PORT_0, string(11, 13, "incrementPulse = "))
      Serial.Dec(USB_PORT_0, incrementPulse)

      Serial.Str(USB_PORT_0, string(11, 13, "localRcDifference = "))
      Serial.Dec(USB_PORT_0, localRcDifference)

  until Serial.RxHowFull(USB_PORT_0) > 0 or localRcDifference > DEFAULT_CHANGE_THRESHOLD_10 or {
  } (checkUserUartFlag == false and checkRcFlag == false)

  waitcnt(debugDelay + cnt)
  Serial.Str(USB_PORT_0, string(11, 13, "After loop in WaitForUser."))

  switchState := ThreePositionState(incrementPulse)
  pSwitchState := switchState

  Serial.Str(USB_PORT_0, string(11, 13, "localRcDifference = "))
  Serial.Dec(USB_PORT_0, localRcDifference)

  Serial.Str(USB_PORT_0, string(11, 13, "End WaitForUser"))
  waitcnt(debugDelay + cnt)

PRI Initialize | local298  ' Serial Cog

  'Serial.AddPort(ELRS_CONTROL_RX_PORT_0, ELRS_CONTROL_RX_16, -1, 0, ELRS_BAUD_416666)
  'Serial.AddPort(ELRS_TELEMETRY_RX_PORT_1, ELRS_TELEMETRY_RX_17, -1, 0, ELRS_BAUD_416666)
  Serial.AddPort(USB_PORT_0, USB_RX_31, USB_TX_30, 0, USB_BAUD_115200)

  serialPasmCog := Serial.Start
  Serial.Str(USB_PORT_0, string(11, 13, "Initialize"))

  cameraCog := Camera.StartRxTx(CAMERA_RX_9, CAMERA_TX_8, 0, CAMERA_BAUD_115200)
  cameraCog--

  '*0326b* crsfCog[ELRS_CONTROL_RX_PORT_0] := ElrsRx[ELRS_CONTROL_RX_PORT_0].StartRx(ELRS_CONTROL_RX_16, ELRS_BAUD_416666)
  '*0326b* crsfCog[ELRS_TELEMETRY_RX_PORT_1] := ElrsRx[ELRS_TELEMETRY_RX_PORT_1].StartRx(ELRS_TELEMETRY_RX_17, ELRS_BAUD_416666)

  'Rc.BuildMask(PALETTE_CYCLE_6, PALETTE_KNOB_7, KNOB0_8, KNOB1_9, KNOB2_10, KNOB3_11)

  'rcMask := Rc.BuildMask(PALETTE_CYCLE_6, VALUE_CYCLE_5, PARAMETER_SELECT_4, -1, -1, -1)
  rcMask := Rc.BuildMask(PALETTE_CYCLE_6, -1, -1, -1, -1, -1)

  rcCog := Rc.Start(rcMask)
  waitcnt(debugDelay + cnt)
  incrementPulse := Rc.Get(0)

  pIncrementPulse := incrementPulse
  switchState := ThreePositionState(incrementPulse)
  pSwitchState := switchState

  'knobPulse := Rc.Get(1)
  'pKnobPulse := knobPulse
  'knobState := U__ComputeKnobState(knobPulse)
  'pKnobState := knobState
  '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "incrementPulse = "))
  '*0326b* Serial.Dec(USB_PORT_0, incrementPulse)
  'Serial.Str(USB_PORT_0, string(11, 13, "knobPulse = "))
  'Serial.Dec(USB_PORT_0, knobPulse)

PRI MainLoop

  '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "MainLoop before HelpScreen"))
  'waitcnt(debugDelay + cnt)

  HelpScreen
  '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "MainLoop after HelpScreen"))
  'waitcnt(debugDelay + cnt)

  repeat

    if checkUserUartFlag
      CheckUserInput

    'waitcnt(debugDelay + cnt)
    if checkCameraFlag
      'Serial.Str(USB_PORT_0, string(11, 13, "MainLoop before CheckCameraInput"))
      CheckCameraInput

    '*0326b* if checkCrsfCommandsFlag
      'Serial.Str(USB_PORT_0, string(11, 13, "MainLoop before CheckCrsf(ELRS_CONTROL_RX_PORT_0"))
      'waitcnt(debugDelay + cnt)
      '*0326b* CheckCrsf(ELRS_CONTROL_RX_PORT_0, crsfCommandTimeout)

    '*0326b* if checkCrsfTelemetryFlag
      'Serial.Str(USB_PORT_0, string(11, 13, "MainLoop before CheckCrsf(ELRS_TELEMETRY_RX_PORT_1"))
      'waitcnt(debugDelay + cnt)

      '*0326b* CheckCrsf(ELRS_TELEMETRY_RX_PORT_1, crsfTelemetyTimeout)
      'CheckTelemetry(crsfTelemetyTimeout)

    'Only check RC input when the UART isn't busy.
    if expectedUserInput == READY_USER_EXPECTED_0 and checkRcFlag
      'Serial.Str(USB_PORT_0, string(11, 13, "MainLoop before CheckRc"))
      'waitcnt(debugDelay + cnt)
      CheckRc

CON

  'packetProgress  enumeration
  '#0, SYNC_CRSF_0, SIZE_CRSF_1, TYPE_CRSF_2, PAYLOAD_CRSF_3, CRC_CRSF_4
  '#0, GET_SIZE_CRSF_0, GET_REST_OF_PACKET_CRSF_2

  SYNC_CRSF_0XC8 = $C8
  CHANNEL_TYPE_CRSF_0X16 = $16
  TELEMETRY_TYPE_CRSF_0X08 = $08
  LQ_TYPE_CRSF_0X02 = $02

 { CRSF_FRAMETYPE_GPS = 0x02,
    CRSF_FRAMETYPE_VARIO = 0x07,
    CRSF_FRAMETYPE_BATTERY_SENSOR = 0x08,
    CRSF_FRAMETYPE_BARO_ALTITUDE = 0x09,
    CRSF_FRAMETYPE_LINK_STATISTICS = 0x14,
    CRSF_FRAMETYPE_OPENTX_SYNC = 0x10,
    CRSF_FRAMETYPE_RADIO_ID = 0x3A,
    CRSF_FRAMETYPE_RC_CHANNELS_PACKED = 0x16,
    CRSF_FRAMETYPE_ATTITUDE = 0x1E,
    CRSF_FRAMETYPE_FLIGHT_MODE = 0x21,
    // Extended Header Frames, range: 0x28 to 0x96
    CRSF_FRAMETYPE_DEVICE_PING = 0x28,
    CRSF_FRAMETYPE_DEVICE_INFO = 0x29,
    CRSF_FRAMETYPE_PARAMETER_SETTINGS_ENTRY = 0x2B,
    CRSF_FRAMETYPE_PARAMETER_READ = 0x2C,
    CRSF_FRAMETYPE_PARAMETER_WRITE = 0x2D,

    //CRSF_FRAMETYPE_ELRS_STATUS = 0x2E, ELRS good/bad packet count and status flags

    CRSF_FRAMETYPE_COMMAND = 0x32,
    // KISS frames
    CRSF_FRAMETYPE_KISS_REQ  = 0x78,
    CRSF_FRAMETYPE_KISS_RESP = 0x79,
    // MSP commands
    CRSF_FRAMETYPE_MSP_REQ = 0x7A,   // response request using msp sequence as command
    CRSF_FRAMETYPE_MSP_RESP = 0x7B,  // reply with 58 byte chunked binary
    CRSF_FRAMETYPE_MSP_WRITE = 0x7C, // write with 8 byte chunked binary (OpenTX outbound telemetry buffer limit)
    // Ardupilot frames
    CRSF_FRAMETYPE_ARDUPILOT_RESP = 0x80,}
  MAX_DATA_SIZE_CRSF_64 = 64
  MAX_CHANNELS_16 = 16
  OVER_SIZE_COUNT_LIMIT_10 = 10
  BAD_START_COUNT_LIMIT_256 = 256

VAR

  long packetTypeCrsf[2], packetSizeCrsf[2], dataSizeCrsf[2]
  long dataRxCountCrsf[2]
  long calculatedChecksumRxCrsf[2]
  long receivedChecksumCrsf[2], goodChecksumCrsf[2]

  long previousInputCrsf[2], goodDataCountCrsf[2]
  long badDataCountCrsf[2], badStartDataCountCrsf[2]
  long overSizeCrsf[2]

  long channelValue0[MAX_CHANNELS_16]
  long channelValue1[MAX_CHANNELS_16]
  byte packetDataCrsfRx0[MAX_DATA_SIZE_CRSF_64]
  byte packetDataCrsfRx1[MAX_DATA_SIZE_CRSF_64]

DAT

'Add a way for the user to adjust these values.
crsfCommandTimeout      long CRSF_TIMEOUT_250MS
crsfTelemetyTimeout     long CRSF_TIMEOUT_250MS

checkCameraFlag         long true
checkRcFlag             long true
checkCrsfCommandsFlag   long false
checkCrsfTelemetryFlag  long false
checkUserUartFlag       long true
overSizeCountLimit      long OVER_SIZE_COUNT_LIMIT_10
badStartCountLimit      long BAD_START_COUNT_LIMIT_256

PRI CheckCrsf(port, packetTimeout) | localTimer, localCharacter, now, goodDataFlag

  goodDataFlag := false
  localCharacter := ElrsRx[port].Rxcheck

  if localCharacter <> -1
    now := cnt
    Serial.Str(USB_PORT_0, string(11, 13, "localCharacter = $"))
    Serial.Hex(USB_PORT_0, localCharacter, 2)
    'SafeTx(USB_PORT_0, localCharacter)

    if localCharacter == SYNC_CRSF_0XC8
      'packetProgress[port] := GET_SIZE_CRSF_0
      badStartDataCountCrsf[port] := 0
      goodDataFlag := RxCrsf(port, packetTimeout, now)
      if goodDataFlag
        goodDataCountCrsf[port]++
        goodDataFlag := StartProcessPacketCrsf(port)
      else
        badDataCountCrsf[port]++
        Serial.Str(USB_PORT_0, string(9, 11, 13, "badDataCountCrsf["))
        Serial.Str(USB_PORT_0, FindString(@rxPortText, port))
        Serial.Str(USB_PORT_0, string("] = "))
        Serial.Dec(USB_PORT_0, badDataCountCrsf[port])
        Serial.Str(USB_PORT_0, string(11, 13, "localCharacter = $"))
        Serial.Hex(USB_PORT_0, localCharacter, 2)
        Serial.Str(USB_PORT_0, string(11, 13, "milliseconds since previousInputCrsf = "))
        Serial.Dec(USB_PORT_0, (now - cameraReplyTimer) / MILLISECOND)
    else
      badStartDataCountCrsf[port]++
      if badStartDataCountCrsf[port] > 64
        Serial.Str(USB_PORT_0, string(9, 11, 13, "badStartDataCountCrsf["))
        Serial.Str(USB_PORT_0, FindString(@rxPortText, port))
        Serial.Str(USB_PORT_0, string("] = "))
        Serial.Dec(USB_PORT_0, badStartDataCountCrsf[port])
        Serial.Str(USB_PORT_0, string(11, 13, "localCharacter = $"))
        Serial.Hex(USB_PORT_0, localCharacter, 2)
      if badStartDataCountCrsf[port] > badStartCountLimit
        Serial.Str(USB_PORT_0, string(11, 13, "badStartCountLimit["))
        Serial.Str(USB_PORT_0, FindString(@rxPortText, port))
        Serial.Str(USB_PORT_0, string("] = "))
        Serial.Dec(USB_PORT_0, badStartCountLimit[port])
        Serial.Str(USB_PORT_0, string(11, 13, "Turn off port "))
        Serial.Str(USB_PORT_0, FindString(@rxPortText, port))
        Serial.Str(USB_PORT_0, string(" ."))
        checkCrsfCommandsFlag[port] := false

    previousInputCrsf[port] := now

  else
    return

  if goodDataFlag
    goodChecksumCrsf[port]++
    goodDataFlag := FinishProcessPacketCrsf(port)


PRI RxCrsf(port, packetTimeout, rxTime) : goodDataFlag | localDifference, localCharacter, {
} localPtr, now, continueCharacter

  localPtr := @packetDataCrsfRx0 + (port * MAX_DATA_SIZE_CRSF_64)
  packetSizeCrsf[port] := ElrsRx[port].Rxcheck

  if packetSizeCrsf[port] > MAX_DATA_SIZE_CRSF_64
    Serial.Str(USB_PORT_0, string(11, 13, "RxCrsf | packetSizeCrsf["))
    Serial.Str(USB_PORT_0, FindString(@rxPortText, port))
    Serial.Str(USB_PORT_0, string("] = "))
    Serial.Dec(USB_PORT_0, packetSizeCrsf[port])

  'continueCharacter := Serial.Rx(USB_PORT_0)

  if packetSizeCrsf[port] > MAX_DATA_SIZE_CRSF_64
    Serial.Str(USB_PORT_0, string(11, 13, "Error! packetSizeCrsf["))
    Serial.Str(USB_PORT_0, FindString(@rxPortText, port))
    Serial.Str(USB_PORT_0, string("] too large."))
    Serial.Str(USB_PORT_0, string(11, 13, "overSizeCrsf["))
    Serial.Str(USB_PORT_0, FindString(@rxPortText, port))
    Serial.Str(USB_PORT_0, string("] = "))
    Serial.Dec(USB_PORT_0, ++overSizeCrsf[port])
    if overSizeCrsf[port] > overSizeCountLimit
      Serial.Str(USB_PORT_0, string(11, 13, "overSizeCountLimit["))
      Serial.Str(USB_PORT_0, FindString(@rxPortText, port))
      Serial.Str(USB_PORT_0, string("] = "))
      Serial.Dec(USB_PORT_0, overSizeCountLimit[port])
      Serial.Str(USB_PORT_0, string(11, 13, "Turn off port "))
      Serial.Str(USB_PORT_0, FindString(@rxPortText, port))
      Serial.Str(USB_PORT_0, string(" ."))
      checkCrsfCommandsFlag[port] := false
    return

  dataRxCountCrsf[port] := 0


  repeat
    localCharacter := ElrsRx[port].Rxcheck
    byte[localPtr++] := localCharacter
    dataRxCountCrsf[port]++
    localDifference := cnt - rxTime

  while dataRxCountCrsf[port] < packetSizeCrsf[port] and localDifference < packetTimeout

  goodDataFlag := dataRxCountCrsf[port] == packetSizeCrsf[port]

  Serial.Str(USB_PORT_0, string(11, 13, "RxCrsf | packetSizeCrsf["))
  Serial.Str(USB_PORT_0, FindString(@rxPortText, port))
  Serial.Str(USB_PORT_0, string("] = "))
  Serial.Dec(USB_PORT_0, packetSizeCrsf[port])

  ifnot goodDataFlag
    Serial.Str(USB_PORT_0, string(9, 11, 13, "Bad Data! | dataRxCountCrsf["))
    Serial.Str(USB_PORT_0, FindString(@rxPortText, port))
    Serial.Str(USB_PORT_0, string("] = "))
    Serial.Dec(USB_PORT_0, dataRxCountCrsf[port])


PUB DumpBuffer(localPtr, bytesToDump) | localIndex

  bytesToDump--
  repeat localIndex from 0 to bytesToDump

    Serial.Str(USB_PORT_0, string(11, 13, "buffer["))
    Serial.Dec(USB_PORT_0, localIndex)
    Serial.Str(USB_PORT_0, string("] = $"))
    Serial.Hex(USB_PORT_0, byte[localPtr][localIndex], 2)

PRI StartProcessPacketCrsf(port) : goodDataFlag | localPtr, testChecksum

  localPtr := @packetDataCrsfRx0 + (port * MAX_DATA_SIZE_CRSF_64)

  'calculatedChecksumRxCrsf[port] := CheckCrc8(localPtr, packetSizeCrsf[port] - 1)
  Serial.Str(USB_PORT_0, string(11, 13, "StartProcessPacketCrsf dump buffer plus two."))
  DumpBuffer(localPtr, packetSizeCrsf[port] + 2)

  calculatedChecksumRxCrsf[port] := CheckCrc8Plus(localPtr, packetSizeCrsf[port] - 1, $31)
  receivedChecksumCrsf[port] := byte[localPtr][packetSizeCrsf[port] - 1]

  goodDataFlag := calculatedChecksumRxCrsf[port] == receivedChecksumCrsf[port]

  Serial.Str(USB_PORT_0, string(11, 13, "StartProcessPacketCrsf | receivedChecksumCrsf["))
  Serial.Str(USB_PORT_0, FindString(@rxPortText, port))
  Serial.Str(USB_PORT_0, string("] = $"))
  Serial.Hex(USB_PORT_0, receivedChecksumCrsf[port], 2)

  ifnot goodDataFlag
    Serial.Str(USB_PORT_0, string(9, 11, 13, "Bad Checksum! | calculatedChecksumRxCrsf["))
    Serial.Str(USB_PORT_0, FindString(@rxPortText, port))
    Serial.Str(USB_PORT_0, string("] = $"))
    Serial.Hex(USB_PORT_0, calculatedChecksumRxCrsf[port], 2)
    testChecksum := CheckCrc8Plus(localPtr, packetSizeCrsf[port] - 2, $31)
    Serial.Str(USB_PORT_0, string(11, 13, "CheckCrc8Plus(localPtr, packetSizeCrsf[port] - 2, $31) testChecksum = $"))
    Serial.Hex(USB_PORT_0, testChecksum, 2)
    testChecksum := CheckCrc8(localPtr, packetSizeCrsf[port] - 1)
    Serial.Str(USB_PORT_0, string(11, 13, "CheckCrc8(localPtr, packetSizeCrsf[port] - 1) testChecksum = $"))
    Serial.Hex(USB_PORT_0, testChecksum, 2)
    testChecksum := CheckCrc8(localPtr, packetSizeCrsf[port] - 2)
    Serial.Str(USB_PORT_0, string(11, 13, "CheckCrc8(localPtr, packetSizeCrsf[port] - 2) testChecksum = $"))
    Serial.Hex(USB_PORT_0, testChecksum, 2)

PRI FinishProcessPacketCrsf(port) : goodDataFlag | localPtr, channelPtr

  localPtr := @packetDataCrsfRx0 + (port * MAX_DATA_SIZE_CRSF_64)

  dataSizeCrsf[port] := packetSizeCrsf[port] - 2
  packetTypeCrsf[port] := byte[localPtr++]

  case packetTypeCrsf[port]
    LQ_TYPE_CRSF_0X02:
      DisplayLqCrsf(port, localPtr)
      goodDataFlag := true

    TELEMETRY_TYPE_CRSF_0X08:
      DisplayTelemetryCrsf(port, localPtr)
      goodDataFlag := true

    CHANNEL_TYPE_CRSF_0X16:
      channelPtr := @channelValue0 + (port * MAX_CHANNELS_16)
      ParseAndDisplayChannelsCrsf(port, localPtr, channelPtr)
      goodDataFlag := true

    Other:
      DisplayOtherCrsf(port, localPtr, packetTypeCrsf[port])
      goodDataFlag := false

PRI DisplayLqCrsf(port, localPtr) | tooFar

  Serial.Str(USB_PORT_0, string(11, 13, "DisplayLqCrsf | dataSizeCrsf["))
  Serial.Str(USB_PORT_0, FindString(@rxPortText, port))
  Serial.Str(USB_PORT_0, string("] = "))
  Serial.Dec(USB_PORT_0, dataSizeCrsf[port])
  tooFar := localPtr + dataSizeCrsf[port]
  Serial.Str(USB_PORT_0, string(11, 13, "Data = $"))

  repeat dataSizeCrsf[port]
    Serial.Hex(USB_PORT_0, byte[localPtr++] , 2)
    if localPtr < tooFar
      Serial.Str(USB_PORT_0, string(", $"))

PRI DisplayTelemetryCrsf(port, localPtr) | tooFar

  Serial.Str(USB_PORT_0, string(11, 13, "DisplayTelemetryCrsf | dataSizeCrsf["))
  Serial.Str(USB_PORT_0, FindString(@rxPortText, port))
  Serial.Str(USB_PORT_0, string("] = "))
  Serial.Dec(USB_PORT_0, dataSizeCrsf[port])
  tooFar := localPtr + dataSizeCrsf[port]
  Serial.Str(USB_PORT_0, string(11, 13, "Data = $"))

  repeat dataSizeCrsf[port]
    Serial.Hex(USB_PORT_0, byte[localPtr++] , 2)
    if localPtr < tooFar
      Serial.Str(USB_PORT_0, string(", $"))

PRI ParseAndDisplayChannelsCrsf(port, localPtr, channelPtr) | tooFar, originalPtr, maxIndex, {
} channelIndex

  originalPtr := localPtr

  Serial.Str(USB_PORT_0, string(11, 13, "ParseAndDisplayChannelsCrsf | dataSizeCrsf["))
  Serial.Str(USB_PORT_0, FindString(@rxPortText, port))
  Serial.Str(USB_PORT_0, string("] = "))
  Serial.Dec(USB_PORT_0, dataSizeCrsf[port])
  tooFar := localPtr + dataSizeCrsf[port]
  Serial.Str(USB_PORT_0, string(11, 13, "Data = $"))

  repeat dataSizeCrsf[port]
    Serial.Hex(USB_PORT_0, byte[localPtr++] , 2)
    if localPtr < tooFar
      Serial.Str(USB_PORT_0, string(", $"))

  maxIndex := ChopChannelsCrsf(port, originalPtr, channelPtr, tooFar)

  Serial.Str(USB_PORT_0, string(11, 13, "max channel index = "))
  Serial.Dec(USB_PORT_0, maxIndex)

  repeat channelIndex from 0 to maxIndex
    Serial.Str(USB_PORT_0, string(11, 13, "channel["))
    Serial.Str(USB_PORT_0, FindString(@channelText, channelIndex))
    Serial.Str(USB_PORT_0, string("] = "))
    Serial.Dec(USB_PORT_0, long[channelPtr][channelIndex])

PRI ChopChannelsCrsf(port, localPtr, channelPtr, tooFar) : channelIndex | longToFill, {
} longToChop, byteAsLong, {
} lowBits, bitsInLong

  Serial.Str(USB_PORT_0, string(11, 13, "ChopChannelsCrsf"))

  longfill(channelPtr, 0, MAX_CHANNELS_16)

  channelIndex := 0


  longToChop := longToFill := bitsInLong := 0

  repeat
    repeat while bitsInLong < 11
      longToFill <<= 8
      byteAsLong := byte[localPtr++]
      longToFill |= byteAsLong
      bitsInLong += 8

    bitsInLong -= 11
    lowBits := FillLowByteMask(bitsInLong)
    longToChop := longToFill
    longToChop >>= bitsInLong 'Leave top 11 bits.
    long[channelPtr][channelIndex++] := longToChop
    longToFill &= lowBits  'Keep bottom bits.

  while localPtr < tooFar


  channelIndex--

{PRI FillHighByteMask(bitsToFill)

  result := FillLowByteMask(bitsToFill)

  result <<= (8 - bitsToFill)
 }
PRI FillLowByteMask(bitsToFill)

  repeat bitsToFill
    result <<= 1
    result |= 1

PRI DisplayOtherCrsf(port, localPtr, localPacketType) | tooFar

  Serial.Str(USB_PORT_0, string(11, 13, "DisplayLqCrsf | dataSizeCrsf["))
  Serial.Str(USB_PORT_0, FindString(@rxPortText, port))
  Serial.Str(USB_PORT_0, string("] = "))
  Serial.Dec(USB_PORT_0, dataSizeCrsf[port])
  Serial.Str(USB_PORT_0, string(11, 13, "packet type = $"))
  Serial.Hex(USB_PORT_0, localPacketType, 2)
  tooFar := localPtr + dataSizeCrsf[port]
  Serial.Str(USB_PORT_0, string(11, 13, "Data = $"))

  repeat dataSizeCrsf[port]
    Serial.Hex(USB_PORT_0, byte[localPtr++] , 2)
    if localPtr < tooFar
      Serial.Str(USB_PORT_0, string(", $"))




{For an RC channels packet (type 0x16):
Sync Byte: 0xC8
Length Byte: 0x19 (25 bytes, including type, 22 bytes of channel data, and CRC)
Type Byte: 0x16
Payload: 22 bytes encoding 16 channels at 11 bits each (packed into 176 bits total).
CRC: 1 byte checksum.
The 11-bit channel values are bit-packed across the payload bytes, requiring the receiver
to unpack them into usable data. For instance, a single 11-bit value might span two bytes,
with bits split across byte boundaries.
}

PUB CheckCrc8(dataPtr, numberOfBytes)
'' numberOfBytes does not include CRC

  repeat numberOfBytes
    result ^= byte[dataPtr++]
    repeat 8
      if result & $80
        result <<= 1
        result ^= $131
      else
        result <<= 1

  'result -= byte[dataPtr]

PUB CheckCrc8Plus(dataPtr, numberOfBytes, poly) : result
'' numberOfBytes does not include CRC

  result := 0

  repeat numberOfBytes
    result ^= byte[dataPtr++]
    repeat 8
      if result & $80
        result <<= 1
        result ^= poly
      else
        result <<= 1
    result &= 255


CON

  'switchState enumeration
  #0, LOW_SWITCH_STATE_0, MIDDLE_SWITCH_STATE_1, HIGH_SWITCH_STATE_2

  CYCLE_BACK_THRESHOLD_1300 = 1300
  CYCLE_FORWARD_THRESHOLD_1700 = 1700

  'NUMBER_OF_PARAMETERS_6 = 6

  {MIN_KNOB_EXPECTED_988 = 988
  MAX_KNOB_EXPECTED_2011 = 2011
  KNOB_RANGE_1023 = MAX_KNOB_EXPECTED_2011 - MIN_KNOB_EXPECTED_988
  KNOB_STEP_91 = KNOB_RANGE_1023 / NUMBER_OF_PALETTES_15
  BUTTON_STEP_170 = KNOB_RANGE_1023 / NUMBER_OF_PARAMETERS_6     }
  DEFAULT_CHANGE_THRESHOLD_10 = 10

VAR '' RC Control Code Below

  long rcMask, rcCog
  long incrementPulse, pIncrementPulse
  long switchState, pSwitchState
  'long knobPulse, pKnobPulse
  'long knobState, pKnobState

DAT '' RC Control Values

cycleBack               long CYCLE_BACK_THRESHOLD_1300
cycleForward            long CYCLE_FORWARD_THRESHOLD_1700
minPalette              long WHITE_HOT_PALETTE_0
maxPalette              long MAX_PALETTE_14

{
parameterSelection      long PALETTE_DATA_21, BRIGHTNESS_DATA_16, CONTRAST_DATA_17
                        long MIRROR_DATA_22, RESET_DATA_9, SAVE_DATA_8
}


PRI CheckRc | localRcDifference[2]

  'Serial.Str(USB_PORT_0, string(", CheckRc"))
  incrementPulse := Rc.Get(0)
  localRcDifference[0] := pIncrementPulse - incrementPulse
  ||localRcDifference[0]

  if localRcDifference[0] > DEFAULT_CHANGE_THRESHOLD_10
    {'*0326b* Serial.Str(USB_PORT_0, string(11, 13, "incrementPulse = "))
    Serial.Dec(USB_PORT_0, incrementPulse)
    Serial.Str(USB_PORT_0, string( ", pIncrementPulse = "))
    Serial.Dec(USB_PORT_0, pIncrementPulse)
    }'*0326b*
    switchState := ThreePositionState(incrementPulse)
    if switchState <> pSwitchState
      case switchState
        LOW_SWITCH_STATE_0:
          '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "targetPalette was = "))
          '*0326b* Serial.Str(USB_PORT_0, FindString(@paletteText, targetPalette))
          targetPalette := AddWithRollover(targetPalette, -1, minPalette, maxPalette)
          '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "targetPalette is = "))
          '*0326b* Serial.Str(USB_PORT_0, FindString(@paletteText, targetPalette))
          txData[0] := targetPalette
          cameraDataType := PALETTE_DATA_21
          'cameraTxRequest := WRITE_CAMERA_TX_REQUEST_2
          expectedUserInput := WRITE_USER_EXPECTED_4

        'MIDDLE_SWITCH_STATE_1: No action
        HIGH_SWITCH_STATE_2:
          '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "targetPalette was = "))
          '*0326b* Serial.Str(USB_PORT_0, FindString(@paletteText, targetPalette))
          targetPalette := AddWithRollover(targetPalette, 1, minPalette, maxPalette)
          '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "targetPalette is = "))
          '*0326b* Serial.Str(USB_PORT_0, FindString(@paletteText, targetPalette))
          txData[0] := targetPalette
          cameraDataType := PALETTE_DATA_21
          'cameraTxRequest := WRITE_CAMERA_TX_REQUEST_2
          expectedUserInput := WRITE_USER_EXPECTED_4

      {'*0326b* Serial.Str(USB_PORT_0, string(11, 13, "switchState = "))
      Serial.Str(USB_PORT_0, FindString(@switchStateText, switchState))
      Serial.Str(USB_PORT_0, string(11, 13, "pSwitchState = "))
      Serial.Str(USB_PORT_0, FindString(@switchStateText, pSwitchState))   }'*0326b*
      pSwitchState := switchState
    pIncrementPulse := incrementPulse

  {knobPulse := Rc.Get(1)
  localRcDifference[1] := pKnobPulse - knobPulse
  ||localRcDifference[1]

  if localRcDifference[1] > DEFAULT_CHANGE_THRESHOLD_10 'knobPulse <> pKnobPulse
    Serial.Str(USB_PORT_0, string(11, 13, "knobPulse = "))
    Serial.Dec(USB_PORT_0, knobPulse)
    Serial.Str(USB_PORT_0, string( ", pKnobPulse = "))
    Serial.Dec(USB_PORT_0, pKnobPulse)
    knobState := U__ComputeKnobState(knobPulse)
    Serial.Str(USB_PORT_0, string(11, 13, "knobState = "))
    Serial.Str(USB_PORT_0, FindString(@paletteText, knobState))
    Serial.Str(USB_PORT_0, string(11, 13, "pKnobState = "))
    Serial.Str(USB_PORT_0, FindString(@paletteText, pKnobState))
    if knobState <> pKnobState
      targetPalette := knobState
      txData[0] := targetPalette
      cameraDataType := PALETTE_DATA_21
      'cameraTxRequest := WRITE_CAMERA_TX_REQUEST_2
      expectedUserInput := WRITE_USER_EXPECTED_4
      pKnobState := knobState
    pKnobPulse := knobPulse  }

PRI ThreePositionState(localPulse) : resultState

  if incrementPulse < cycleBack
    resultState := LOW_SWITCH_STATE_0
  elseif incrementPulse < cycleForward
    resultState := MIDDLE_SWITCH_STATE_1
  else
    resultState := HIGH_SWITCH_STATE_2

{PRI U__ComputeKnobState(localPulse) : resultState

  localPulse -= MIN_KNOB_EXPECTED_988
  resultState := minPalette #> (localPulse / KNOB_STEP_91) <# ICE_FIRE_PALETTE_10
   }
PUB AddWithRollover(value, change, localMin, localMax) | range

  range := (localMax - localMin) + 1
  result := value + change
  if result < localMin
    repeat while result < localMin
      result += range
  if result > localMax
    repeat while result > localMax
      result -= range

VAR '' User UART Code Below
PRI CheckUserInput | localCharacter, localDifference, goodDataFlag

  if expectedUserInput <> pExpectedUserInput
    {'*0326b* Serial.Str(USB_PORT_0, string(11, 13, "CheckUserInput | expectedUserInput = "))
    Serial.Str(USB_PORT_0, FindString(@expectedUserInputText, expectedUserInput))
    Serial.Str(USB_PORT_0, string(11, 13, "pExpectedUserInput = "))
    Serial.Str(USB_PORT_0, FindString(@expectedUserInputText, pExpectedUserInput))}'*0326b*
    pExpectedUserInput := expectedUserInput

  case expectedUserInput

    READ_USER_EXPECTED_1:
      pCompleteRxCount := completeRxCount
      '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "READ_USER_EXPECTED_1: | completeRxCount = "))
      '*0326b* Serial.Dec(USB_PORT_0, completeRxCount)
      ProcessReadCommand
      expectedUserInput := WAIT_FOR_READ_USER_EXPECTED_2
      cameraReplyTimer := cnt
      return

    WAIT_FOR_READ_USER_EXPECTED_2, WAIT_FOR_WRITE_USER_EXPECTED_5:
      localDifference := cnt - cameraReplyTimer
      if localDifference > CAMERA_REPLY_TIMEOUT_2S
        Serial.Str(USB_PORT_0, string(11, 13, "milliseconds since camera request = "))
        Serial.Dec(USB_PORT_0, (cnt - cameraReplyTimer) / MILLISECOND)
        CameraReplyTimeout
        expectedUserInput := READY_USER_EXPECTED_0

      elseif completeRxCount <> pCompleteRxCount
       {'*0326b* Serial.Str(USB_PORT_0, string(11, 13, "milliseconds since camera request = "))
        Serial.Dec(USB_PORT_0, (cnt - cameraReplyTimer) / MILLISECOND)
        Serial.Str(USB_PORT_0, string(11, 13, "WAIT_FOR_READ_USER_EXPECTED_2, WAIT_FOR_WRITE_USER_EXPECTED_5: | completeRxCount = "))
        Serial.Dec(USB_PORT_0, completeRxCount)
        Serial.Str(USB_PORT_0, string(11, 13, "pCompleteRxCount = "))
        Serial.Dec(USB_PORT_0, pCompleteRxCount)
        }'*0326b*
        if expectedUserInput == WAIT_FOR_READ_USER_EXPECTED_2
          expectedUserInput := READY_USER_EXPECTED_0
        elseif readAfterWriteFlag == true and writeOnlyFlag == false
          '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "Automatically read after write."))
          expectedUserInput := READ_USER_EXPECTED_1

      return

    DATA_INPUT_USER_EXPECTED_3:
      goodDataFlag := ProcessDataInput

      '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "(DATA_INPUT_USER_EXPECTED_3) goodDataFlag = "))
      '*0326b* Serial.Dec(USB_PORT_0, goodDataFlag)
      if goodDataFlag

        expectedUserInput := WRITE_USER_EXPECTED_4

      else
        expectedUserInput := READY_USER_EXPECTED_0
      return

    WRITE_USER_EXPECTED_4:
      pCompleteRxCount := completeRxCount
      '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "WRITE_USER_EXPECTED_4: | completeRxCount = "))
      '*0326b* Serial.Dec(USB_PORT_0, completeRxCount)
      ProcessWriteCommand
      expectedUserInput := WAIT_FOR_WRITE_USER_EXPECTED_5
      cameraReplyTimer := cnt
      return

  localCharacter := Serial.Rxcheck(USB_PORT_0)
  if localCharacter <> -1
    ProcessUserInput(localCharacter)

PRI ProcessUserInput(localCharacter) | goodDataFlag, localDifference 'Camera control from terminal.

  Serial.Str(USB_PORT_0, string(11, 13, "ProcessUserInput()"))
  Serial.Str(USB_PORT_0, string(9, 11, 13, "expectedUserInput was = "))
  Serial.Str(USB_PORT_0, FindString(@expectedUserInputText, expectedUserInput))
  case expectedUserInput
    READY_USER_EXPECTED_0:
      GetUserCommand(localCharacter)

  Serial.Str(USB_PORT_0, string(11, 13, "End ProcessUserInput() | expectedUserInput is = "))
  Serial.Str(USB_PORT_0, FindString(@expectedUserInputText, expectedUserInput))

PRI CameraReplyTimeout

  Serial.Str(USB_PORT_0, string(9, 11, 13, "Timeout error!"))
  Serial.Str(USB_PORT_0, string(9, 11, 13, "expectedUserInput was = "))
  Serial.Dec(USB_PORT_0, expectedUserInput)
  Serial.Str(USB_PORT_0, string(" = "))
  Serial.Str(USB_PORT_0, FindString(@expectedUserInputText, expectedUserInput))
  Serial.Str(USB_PORT_0, string(11, 13, "cameraTimeoutCount = "))
  Serial.Dec(USB_PORT_0, ++cameraTimeoutCount)

PRI GetUserCommand(localCharacter) 'Camera control from terminal. No expectation.


  Serial.Str(USB_PORT_0, string(11, 13, "GetUserCommand()"))
  Serial.Str(USB_PORT_0, string(11, 13, "localCharacter = "))
  SafeTx(USB_PORT_0, localCharacter)

  writeOnlyFlag := false

  case localCharacter
    {'*0326b*
    "1":
      !checkRcFlag
    "2":
      !checkCrsfCommandsFlag
    "3":
      !checkCrsfTelemetryFlag
    "4":
      !checkCameraFlag
     }'*0326b*
    "b":
      cameraDataType := BRIGHTNESS_DATA_16
      expectedUserInput := READ_USER_EXPECTED_1
    "B": 'Brightness
      cameraDataType := BRIGHTNESS_DATA_16
      expectedUserInput := DATA_INPUT_USER_EXPECTED_3
      DisplayParameter(string("brightness"), 0, 100, 50)

    "c":
      cameraDataType := CONTRAST_DATA_17
      expectedUserInput := READ_USER_EXPECTED_1
    "C":
      cameraDataType := CONTRAST_DATA_17
      expectedUserInput := DATA_INPUT_USER_EXPECTED_3
      DisplayParameter(string("contrast"), 0, 100, 50)

    "d":
      cameraDataType := STATIC_DENOISING_DATA_19
      expectedUserInput := READ_USER_EXPECTED_1
    "D":
      cameraDataType := STATIC_DENOISING_DATA_19
      expectedUserInput := DATA_INPUT_USER_EXPECTED_3
      DisplayParameter(string("static denoising"), 0, 100, 50)

    "y":
      cameraDataType := DYNAMIC_DENOISING_DATA_20
      expectedUserInput := READ_USER_EXPECTED_1
    "Y":
      cameraDataType := DYNAMIC_DENOISING_DATA_20
      expectedUserInput := DATA_INPUT_USER_EXPECTED_3
      DisplayParameter(string("dynamic denoising"), 0, 100, 50)

    "m":
      cameraDataType := MIRROR_DATA_22
      expectedUserInput := READ_USER_EXPECTED_1
    "M":
      cameraDataType := MIRROR_DATA_22
      expectedUserInput := DATA_INPUT_USER_EXPECTED_3
      DisplayMirroring

    "p":
      cameraDataType := PALETTE_DATA_21
      expectedUserInput := READ_USER_EXPECTED_1
    "P": 'Palette
      cameraDataType := PALETTE_DATA_21
      expectedUserInput := DATA_INPUT_USER_EXPECTED_3
      DisplayPalettes

    "o", "O":
      cameraDataType := MODEL_DATA_1
      expectedUserInput := READ_USER_EXPECTED_1

    "s", "S":
      cameraDataType := SAVE_DATA_8
      expectedUserInput := DATA_INPUT_USER_EXPECTED_3
      DisplaySelection(string("save current settings"), 0)
      writeOnlyFlag := true

    "r", "R":
      cameraDataType := RESET_DATA_9
      expectedUserInput := DATA_INPUT_USER_EXPECTED_3
      DisplaySelection(string("reset to factory settings"), 0)
      writeOnlyFlag := true

    "k", "K":
      DisplayKnownParameters
    other: '10, 13, "h", "H", "?":

      HelpScreen 'Think about screen formatting. Should the screen be cleared?


  {'*0326b* Serial.Str(USB_PORT_0, string(11, 13, "End GetUserCommand()"))
  Serial.Str(USB_PORT_0, string(11, 13, "cameraDataType = "))
  Serial.Str(USB_PORT_0, FindString(@cameraDataTypeText, cameraDataType))
  Serial.Str(USB_PORT_0, string(11, 13, "expectedUserInput = "))
  Serial.Str(USB_PORT_0, FindString(@expectedUserInputText, expectedUserInput))
  }'*0326b*

PRI ProcessReadCommand

  {'*0326b* Serial.Str(USB_PORT_0, string(11, 13, "ProcessReadCommand"))
  Serial.Str(USB_PORT_0, string(11, 13, "cameraDataTypeInput = "))
  Serial.Str(USB_PORT_0, FindString(@cameraDataTypeText, cameraDataType))
  Serial.Str(USB_PORT_0, string(11, 13, "programName = "))
  Serial.Str(USB_PORT_0, @programName)
   }'*0326b*
  txSize := 5
  cameraClassTx := classAndSubclass[cameraDataType] >> 8
  cameraClassTx &= $FF
  cameraSubclassTx := classAndSubclass[cameraDataType] & $FF
  cameraFlagTx := READ_FLAG_1
  txData[0] := 0
  cameraTxRequest := READ_CAMERA_TX_REQUEST_1

PRI ProcessWriteCommand

  {'*0326b* Serial.Str(USB_PORT_0, string(11, 13, "ProcessWriteCommand"))
  Serial.Str(USB_PORT_0, string(11, 13, "cameraDataTypeInput = "))
  Serial.Str(USB_PORT_0, FindString(@cameraDataTypeText, cameraDataType))
  Serial.Str(USB_PORT_0, string(11, 13, "programName = "))
  Serial.Str(USB_PORT_0, @programName)
  }'*0326b*
  txSize := 5
  cameraClassTx := classAndSubclass[cameraDataType] >> 8
  cameraClassTx &= $FF
  cameraSubclassTx := classAndSubclass[cameraDataType] & $FF
  cameraFlagTx := WRITE_FLAG_0
  cameraTxRequest := WRITE_CAMERA_TX_REQUEST_2

PRI ProcessDataInput : goodDataFlag

  {'*0326b* Serial.Str(USB_PORT_0, string(11, 13, "ProcessDataInput"))
  Serial.Str(USB_PORT_0, string(11, 13, "cameraDataTypeInput = "))
  Serial.Str(USB_PORT_0, FindString(@cameraDataTypeText, cameraDataType))
  }'*0326b*
  case cameraDataType
    {NO_DATA_0, MODEL_DATA_1:
    FPGA_VERSION_DATA_2:
    FPGA_TIME_DATA_3:
    SOFTWARE_VERSION_DATA_4:
    SOFTWARE_TIME_DATA_5:
    CAL_TIME_DATA_6:
    ISP_DATA_7:}
    SAVE_DATA_8:
      goodDataFlag := ConfirmSelection
    RESET_DATA_9:
      goodDataFlag := ConfirmSelection
    SHUTTER_DATA_10:
    BACKGROUND_DATA_11:
    VIGNETTING_DATA_12:
    AUTO_SHUTTER_DATA_13:
    AUTO_INTERVAL_DATA_14:
    DEFECTIVE_PIXEL_DATA_15:
    BRIGHTNESS_DATA_16:
      goodDataFlag := SetParameter
    CONTRAST_DATA_17:
      goodDataFlag := SetParameter
    ENHANCEMENT_DATA_18:
    STATIC_DENOISING_DATA_19:
      goodDataFlag := SetParameter
    DYNAMIC_DENOISING_DATA_20:
      goodDataFlag := SetParameter
    PALETTE_DATA_21:
      goodDataFlag := SetPalette
    MIRROR_DATA_22:
      goodDataFlag := SetMirroring
    INIT_STATE_REQUEST_DATA_23:

    other:
      if cameraDataType < NO_DATA_0 or cameraDataType > INIT_STATE_REQUEST_DATA_23
        Serial.Str(USB_PORT_0, string(11, 13, "The value of cameraDataType is out of range."))
      else
        Serial.Str(USB_PORT_0, string(9, 11, 13, "None supported cameraDataType. cameraDataType = "))
        Serial.Str(USB_PORT_0, FindString(@cameraDataTypeText, cameraDataType))


PRI DisplaySelection(parameterNameLocal, newData)

  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "Y", 34, " to comfirm "))
  Serial.Str(USB_PORT_0, parameterNameLocal)
  Serial.Str(USB_PORT_0, string(" request."))
  txData[0] := newData

PRI ConfirmSelection : goodDataFlag | localCharacter

  localCharacter := Serial.Rx(USB_PORT_0)
  if localCharacter == "y" or localCharacter == "Y"

    goodDataFlag := true

PRI SetPalette : goodDataFlag | localCharacter

  Serial.Str(USB_PORT_0, string(11, 13, "Start SetPalette"))
  Serial.Str(USB_PORT_0, string(11, 13, "Enter new palette."))

  localCharacter := Serial.Rx(USB_PORT_0)
  Serial.Str(USB_PORT_0, string(11, 13, "User input = "))
  SafeTx(USB_PORT_0, localCharacter)

  case localCharacter

    "A".."E":  'Treat "A" as ten.
      'Only five hexadecimal values allowed in this example. Makes convertion easier.
      txData[0] := 10 + localCharacter - "A"
      goodDataFlag := true

    "a".."e":  'Treat "a" as ten.
      'Only five hexadecimal values allowed in this example. Makes convertion easier.
      txData[0] := 10 + localCharacter - "a"
      goodDataFlag := true

    "0".."9":

      txData[0] := localCharacter - "0" 'Convert ASCII numeric character to number.
      goodDataFlag := true

    "x", "X", "q", "Q", "n", "N": 'Multiple ways to exit.
      Serial.Str(USB_PORT_0, string(11, 13, "Exiting palette input."))

    other:
      Serial.Str(USB_PORT_0, string(11, 13, "Not a valid input."))

  if goodDataFlag
    Serial.Str(USB_PORT_0, string(11, 13, "New palette = "))
    Serial.Str(USB_PORT_0, FindString(@paletteText, txData[0]))

  Serial.Str(USB_PORT_0, string(11, 13, "End SetPalette. cameraTxRequest = "))
  Serial.Str(USB_PORT_0, FindString(@cameraTxRequestText, cameraTxRequest))

PRI DisplayPalettes | paletteIndex

  Serial.Str(USB_PORT_0, string(11, 13, "Thermal Camera Palettes"))

  repeat paletteIndex from minPalette to maxPalette
    Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34))
    if paletteIndex > COLOR2_PALETTE_9 '
      Serial.Tx(USB_PORT_0, "a" + (paletteIndex - ICE_FIRE_PALETTE_10))
    else
      Serial.Dec(USB_PORT_0, paletteIndex)
    Serial.Str(USB_PORT_0, string(34, " to set palette to "))
    Serial.Str(USB_PORT_0, FindString(@paletteText, paletteIndex))
    Serial.Tx(USB_PORT_0, ".")
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "x", 34, " to eXit and not change the palette."))

PRI DisplayMirroring | mirroringIndex

  Serial.Str(USB_PORT_0, string(11, 13, "Thermal Camera Image Mirroring Settings"))

  repeat mirroringIndex from NO_MIRRORING_0 to UP_AND_DOWN_MIRRORING_3
    Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34))
    Serial.Dec(USB_PORT_0, mirroringIndex)
    Serial.Str(USB_PORT_0, string(34, " to set mirroring to "))
    Serial.Str(USB_PORT_0, FindString(@mirroringText, mirroringIndex))
    Serial.Tx(USB_PORT_0, ".")
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "x", 34, " to eXit and not change the mirroring setting."))

PRI SetMirroring : goodDataFlag | localCharacter

   localCharacter := Serial.Rx(USB_PORT_0)

  Serial.Str(USB_PORT_0, string(11, 13, "User input = "))
  SafeTx(USB_PORT_0, localCharacter)


  case localCharacter

    "0".."3":

      txData[0] := localCharacter - "0" 'Convert ASCII numeric character to number.
      goodDataFlag := true

    "4".."9":
      Serial.Str(USB_PORT_0, string(11, 13, "Data outside allowed range."))

    "x", "X", "q", "Q", "n", "N": 'Multiple ways to exit.
      Serial.Str(USB_PORT_0, string(11, 13, "Exiting palette input."))

    other:
      Serial.Str(USB_PORT_0, string(11, 13, "Not a valid input."))

  if goodDataFlag
    Serial.Str(USB_PORT_0, string(11, 13, "New mirroring value = "))
    'Serial.Dec(USB_PORT_0, txData[0])
    Serial.Str(USB_PORT_0, FindString(@mirroringText, txData[0]))


PRI DisplayParameter(parameterNameLocal, minParameterLocal, maxParameterLocal, defaultValue)

  longmove(@parameterName, @parameterNameLocal, 3)
  Serial.Str(USB_PORT_0, string(11, 13, "Set new "))
  Serial.Str(USB_PORT_0, parameterName)
  Serial.Str(USB_PORT_0, string(" value."))
  Serial.Str(USB_PORT_0, string(11, 13, "The new "))
  Serial.Str(USB_PORT_0, parameterName)
  Serial.Str(USB_PORT_0, string(" value should be between "))
  Serial.Dec(USB_PORT_0, minParameter)
  Serial.Str(USB_PORT_0, string(" and "))
  Serial.Dec(USB_PORT_0, maxParameter)
  Serial.Str(USB_PORT_0, string("."))
  Serial.Str(USB_PORT_0, string(" value."))
  Serial.Str(USB_PORT_0, string(11, 13, "The default value is "))
  Serial.Dec(USB_PORT_0, defaultValue)
  Serial.Str(USB_PORT_0, string("."))

PRI SetParameter : goodDataFlag | newValue

  newValue := GetNumber
  if newValue == NOT_A_NUMBER
    Serial.Str(USB_PORT_0, string(11, 13, "Invalid data entry."))
  else
    goodDataFlag := CheckLimits(newValue, minParameter, maxParameter)
    if goodDataFlag
      txData[0] := newValue
      Serial.Str(USB_PORT_0, string(11, 13, "New "))
      Serial.Str(USB_PORT_0, parameterName)
      Serial.Str(USB_PORT_0, string(" value = "))
      Serial.Dec(USB_PORT_0, txData[0])
    else
      Serial.Str(USB_PORT_0, string(11, 13, "Data outside allowed range."))

PRI GetNumber : newValue | finishFlag, validInputFlag, localCharacter
' Only positive numbers. Presently only used for byte sized numbers.

  finishFlag := false
  validInputFlag := false

  repeat until finishFlag
    localCharacter := Serial.Rx(USB_PORT_0)
    case localCharacter
      10, 13:
        ifnot validInputFlag 'Make sure at least one number has been entered.
          newValue := NOT_A_NUMBER
        finishFlag := true

      "0".."9":
        newValue *= 10
        newValue += localCharacter - "0"
        validInputFlag := true

     other:
       newValue := NOT_A_NUMBER
       finishFlag := true

PRI CheckLimits(valueToCheck, lowLimit, highLimit) : goodDataFlag

  if valueToCheck < lowLimit
    Serial.Str(USB_PORT_0, string(11, 13, "The value entered is too low."))
    Serial.Str(USB_PORT_0, string(9, 11, 13, "Lower Limit = "))
    Serial.Dec(USB_PORT_0, lowLimit)
    Serial.Str(USB_PORT_0, string(11, 13, "You Entered = "))
    Serial.Dec(USB_PORT_0, valueToCheck)
    goodDataFlag := false
  elseif valueToCheck > highLimit
    Serial.Str(USB_PORT_0, string(11, 13, "The value entered is too high."))
    Serial.Str(USB_PORT_0, string(9, 11, 13, "Upper Limit = "))
    Serial.Dec(USB_PORT_0, highLimit)
    Serial.Str(USB_PORT_0, string(11, 13, "You Entered = "))
    Serial.Dec(USB_PORT_0, valueToCheck)
    goodDataFlag := false
  else
    goodDataFlag := true

{PRI DebugHelp

  result := Telemetry.GetDebug(0)
  Serial.Str(USB_PORT_0, string(11, 13, "buffFromCog = "))
  Serial.Dec(USB_PORT_0, result)
  result := Telemetry.GetDebug(1)
  Serial.Str(USB_PORT_0, string(11, 13, "headFromCog = "))
  Serial.Dec(USB_PORT_0, result)
  result := Telemetry.GetDebug(2)
  Serial.Str(USB_PORT_0, string(11, 13, "activeFromCog = "))
  Serial.Dec(USB_PORT_0, result)
  result := Telemetry.GetDebug(3)
  Serial.Str(USB_PORT_0, string(11, 13, "rx_head = "))
  Serial.Dec(USB_PORT_0, result)
  result := Telemetry.GetDebug(4)
  Serial.Str(USB_PORT_0, string(11, 13, "rx_tail = "))
  Serial.Dec(USB_PORT_0, result)
  result := Telemetry.GetDebug(5)
  Serial.Str(USB_PORT_0, string(11, 13, "rx_pin = "))
  Serial.Dec(USB_PORT_0, result)
  result := Telemetry.GetDebug(6)
  Serial.Str(USB_PORT_0, string(11, 13, "bit_ticks = "))
  Serial.Dec(USB_PORT_0, result)
  result := Telemetry.GetDebug(7)
  Serial.Str(USB_PORT_0, string(11, 13, "buffer_ptr = "))
  Serial.Dec(USB_PORT_0, result)

    }
{long buffFromCog
  long headFromCog
  long activeFromCog

  long rx_head                                         '59 contiguous longs (must keep order)
  long rx_tail
  long rx_pin
  long bit_ticks
  long buffer_ptr}
PRI HelpScreen

  '*0326b* ifnot checkUserUartFlag
  '*0326b*   return

  Serial.Str(USB_PORT_0, string(11, 13, 11, 13, "Help Screen"))
  Serial.Str(USB_PORT_0, string(11, 13, "programName = "))
  Serial.Str(USB_PORT_0, @programName)
  {'*0326b* Serial.Str(USB_PORT_0, string(11, 13, "ELRS_BAUD_416666 = "))
  Serial.Dec(USB_PORT_0, ELRS_BAUD_416666)

  Serial.Str(USB_PORT_0, string(11, 13, "cameraCog = "))
  Serial.Dec(USB_PORT_0, cameraCog)
  Serial.Str(USB_PORT_0, string(11, 13, "crsfCog[ELRS_CONTROL_RX_PORT_0] = "))
  Serial.Dec(USB_PORT_0, crsfCog[ELRS_CONTROL_RX_PORT_0])
  Serial.Str(USB_PORT_0, string(11, 13, "crsfCog[ELRS_TELEMETRY_RX_PORT_1] = "))
  Serial.Dec(USB_PORT_0, crsfCog[ELRS_TELEMETRY_RX_PORT_1])

  'DebugHelp

  if checkCrsfCommandsFlag and checkRcFlag
    Serial.Str(USB_PORT_0, string(11, 13, 11, 13, "Currently both RC pulses CRSF UART input are checked."))
    Serial.Str(USB_PORT_0, string(11, 13, "If one of these input options isn't needed, turn it off."))

  if checkRcFlag
    Serial.Str(USB_PORT_0, string(11, 13, 11, 13, "RC pulses ARE currently checked."))
    Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "1", 34, " to stop checking RC pulses."))

  else
    Serial.Str(USB_PORT_0, string(11, 13, 11, 13, "RC pulses are NOT checked."))
    Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "1", 34, " to check for RC pulses."))

  if checkCrsfCommandsFlag
    Serial.Str(USB_PORT_0, string(11, 13, 11, 13, "The CRSF command UART is currently checked."))
    Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "2", 34, " to stop checking the CRSF command UART."))

  else
    Serial.Str(USB_PORT_0, string(11, 13, 11, 13, "The CRSF command UART is NOT currently checked."))
    Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "2", 34, " to start checking the CRSF command UART."))

  if checkCrsfTelemetryFlag
    Serial.Str(USB_PORT_0, string(11, 13, 11, 13, "The CRSF telemetry UART is currently checked."))
    Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "3", 34, " to stop checking the CRSF telemetry UART."))

  else
    Serial.Str(USB_PORT_0, string(11, 13, 11, 13, "The CRSF telemetry UART is NOT currently checked."))
    Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "3", 34, " to start checking the CRSF telemetry UART."))
  }'*0326b*

  if checkCameraFlag
    '*0326b* Serial.Str(USB_PORT_0, string(11, 13, 11, 13, "The thermal camera UART is presently ON."))
    '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "4", 34, " to turn off the thermal camera uart."))

    CameraHelpScreen
  {'*0326b* else
    Serial.Str(USB_PORT_0, string(11, 13, 11, 13, "The thermal camera UART is presently OFF."))
    Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "4", 34, " to turn on the thermal camera uart."))
    }'*0326b*
  Serial.Str(USB_PORT_0, string(11, 13, 11, 13, "Press ", 34, "h", 34, " to display this help screen.", 11, 13))

PRI CameraHelpScreen

  Serial.Str(USB_PORT_0, string(11, 13, 11, 13, "Thermal Camera Help Screen"))
  Serial.Str(USB_PORT_0, string(11, 13, "Use upper case letters to select the parameter to write."))
  Serial.Str(USB_PORT_0, string(11, 13, "Use lower case letters to select the parameter to read."))
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "b", 34, " to read Brightness setting."))
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "B", 34, " to set Brightness."))
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "c", 34, " to read Contrast setting."))
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "C", 34, " to set Contrast."))
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "d", 34, " to read static Denoising setting."))
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "D", 34, " to set static Denoising level."))
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "y", 34, " to read dYnamic denoising setting."))
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "Y", 34, " to set dYnamic denoising level."))
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "e", 34, " to read digital Enhancement setting."))
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "E", 34, " to set digital Enhancement."))
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "m", 34, " to read image Mirroring setting."))
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "M", 34, " to set image Mirroring."))
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "p", 34, " to read camera Palette."))
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "P", 34, " to set camera Palette."))
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "o", 34, " to read camera mOde. (Read only.)"))
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "R", 34, " to Reset camera. (Write only.)"))
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "S", 34, " to Save current camera settings. (Write only.)"))
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "T", 34, " to turn off Thermal camera uart."))
  Serial.Str(USB_PORT_0, string(11, 13, "Press ", 34, "K", 34, " to display Known parameters."))


PRI DisplayKnownParameters | parameterIndex, foundParametersRead, foundParametersWrite

  foundParametersRead := foundParametersWrite := 0

  Serial.Str(USB_PORT_0, string(11, 13, 11, 13, "DisplayKnownParameters"))

  Serial.Str(USB_PORT_0, string(11, 13, "Parameters from Reads", 11, 13))

  repeat parameterIndex from MODEL_DATA_1 to INIT_STATE_REPLY_DATA_24
    if parametersFromRead[parameterIndex] <> NOT_A_NUMBER
      foundParametersRead++
      Serial.Str(USB_PORT_0, string(11, 13, "parametersFromRead["))
      Serial.Str(USB_PORT_0, FindString(@cameraDataTypeText, parameterIndex))
      Serial.Str(USB_PORT_0, string("] = "))
      Serial.Dec(USB_PORT_0, parametersFromRead[parameterIndex])
      if parameterIndex == MODEL_DATA_1
        Serial.Str(USB_PORT_0, string(", Camera Model = ", 34))
        SafeStr(USB_PORT_0, @modelDataBuffer, modelDataSize)
        Serial.Tx(USB_PORT_0, 34)
      elseif parameterIndex ==  PALETTE_DATA_21
        Serial.Str(USB_PORT_0, string(", palette = "))
        Serial.Str(USB_PORT_0, FindString(@paletteText, parametersFromRead[parameterIndex]))
      elseif parameterIndex ==  MIRROR_DATA_22
        Serial.Str(USB_PORT_0, string(", mirroring = "))
        Serial.Str(USB_PORT_0, FindString(@mirroringText, parametersFromRead[parameterIndex]))

  '*0326b* Serial.Str(USB_PORT_0, string(11, 13, 11, 13, "Parameters returned when writing."))
  '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "These returned values are not neccessaryily useful.", 11, 13, 11, 13))

  repeat parameterIndex from MODEL_DATA_1 to INIT_STATE_REPLY_DATA_24
    if parametersFromWrite[parameterIndex] <> NOT_A_NUMBER
      foundParametersWrite++
      {'*0326b* Serial.Str(USB_PORT_0, string(11, 13, "parametersFromWrite["))
      Serial.Str(USB_PORT_0, FindString(@cameraDataTypeText, parameterIndex))
      Serial.Str(USB_PORT_0, string("] = "))
      Serial.Dec(USB_PORT_0, parametersFromWrite[parameterIndex])
      if parameterIndex ==  PALETTE_DATA_21
        Serial.Str(USB_PORT_0, string(", palette = "))
        Serial.Str(USB_PORT_0, FindString(@paletteText, parametersFromWrite[parameterIndex]))
      elseif parameterIndex ==  MIRROR_DATA_22
        Serial.Str(USB_PORT_0, string(", mirroring = "))
        Serial.Str(USB_PORT_0, FindString(@mirroringText, parametersFromWrite[parameterIndex]))
       }'*0326b*
  '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "foundParametersRead = "))
  '*0326b* Serial.Dec(USB_PORT_0, foundParametersRead)
  Serial.Str(USB_PORT_0, string(11, 13, "foundParametersWrite = "))
  Serial.Dec(USB_PORT_0, foundParametersWrite)
  Serial.Str(USB_PORT_0, string(11, 13, "End DisplayKnownParameters", 11, 13))


VAR '' Camera UART Code Below


PRI CheckCameraOutput

  case cameraTxRequest
    READ_CAMERA_TX_REQUEST_1, WRITE_CAMERA_TX_REQUEST_2:
      {'*0326b* Serial.Str(USB_PORT_0, string(11, 13, "CheckCameraOutput | cameraTxRequest = "))
      Serial.Str(USB_PORT_0, FindString(@cameraTxRequestText, cameraTxRequest))
      Serial.Str(USB_PORT_0, string(9, 11, 13, "packetProgress was = "))
      Serial.Str(USB_PORT_0, FindString(@packetProgressText, packetProgress)) }'*0326b*
      TxToCamera
      frozenCameraTxRequest := cameraTxRequest
      cameraTxRequest := NO_CAMERA_TX_REQUEST_0

PRI CheckCameraInput | localCharacter, changeFlag

  changeFlag := false

  if cameraTxRequest <> pCameraTxRequest
    {'*0326b* Serial.Str(USB_PORT_0, string(11, 13, "CheckCameraInput | cameraTxRequest = "))
    Serial.Str(USB_PORT_0, FindString(@cameraTxRequestText, cameraTxRequest))
    Serial.Str(USB_PORT_0, string(11, 13, "pCameraTxRequest = "))
    Serial.Str(USB_PORT_0, FindString(@cameraTxRequestText, pCameraTxRequest))
    Serial.Str(USB_PORT_0, string(11, 13, "frozenCameraTxRequest = "))
    Serial.Str(USB_PORT_0, FindString(@cameraTxRequestText, frozenCameraTxRequest))  }
    pCameraTxRequest := cameraTxRequest
    changeFlag := true

  localCharacter := Camera.RxCheck
  if localCharacter <> -1
    ProcessCameraInput(localCharacter)

  CheckCameraOutput
  '*0326b* if changeFlag
    '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "End CheckCameraInput"))

PRI ProcessCameraError(localCharacter)

  Serial.Str(USB_PORT_0, string(9, 11, 13, "ProcessCameraError() ERROR! | localCharacter = $"))
  Serial.Hex(USB_PORT_0, localCharacter, 2)
  Serial.Str(USB_PORT_0, string(9, 11, 13, "packetProgress was = "))
  Serial.Dec(USB_PORT_0, packetProgress)
  Serial.Str(USB_PORT_0, string(" = "))
  Serial.Str(USB_PORT_0, FindString(@packetProgressText, packetProgress))
  Serial.Str(USB_PORT_0, string(11, 13, "cameraInputErrorCount = "))
  Serial.Dec(USB_PORT_0, ++cameraInputErrorCount)
  packetProgress := NONE_PACKET_RX_0

PRI ProcessUnexpectedCameraPacket

  Serial.Str(USB_PORT_0, string(9, 11, 13, "ProcessUnexpectedCameraPacket ERROR!"))
  Serial.Str(USB_PORT_0, string(9, 11, 13, "packetProgress was = "))
  Serial.Dec(USB_PORT_0, packetProgress)
  Serial.Str(USB_PORT_0, string(" = "))
  Serial.Str(USB_PORT_0, FindString(@packetProgressText, packetProgress))
  Serial.Str(USB_PORT_0, string(11, 13, "unexpectedPacketCount = "))
  Serial.Dec(USB_PORT_0, ++unexpectedPacketCount)
  packetProgress := NONE_PACKET_RX_0

PRI ProcessCameraInput(localCharacter)

  '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "ProcessCameraInput | localCharacter = $"))
  '*0326b* Serial.Hex(USB_PORT_0, localCharacter, 2)

  if packetProgress <> pPacketProgress
    {'*0326b* Serial.Str(USB_PORT_0, string(11, 13, "ProcessCameraInput | packetProgress = "))
    Serial.Str(USB_PORT_0, FindString(@packetProgressText, packetProgress))
    Serial.Str(USB_PORT_0, string(11, 13, "pPacketProgress = "))
    Serial.Str(USB_PORT_0, FindString(@packetProgressText, pPacketProgress))   }'*0326b*
    pPacketProgress := packetProgress
  '*0326b* else
    '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "ProcessCameraInput no change in packetProgress."))

  case packetProgress '"packetProgress" indicates which part of the process has been completed.
    NONE_PACKET_RX_0:
      if localCharacter == PACKET_START_0XF0
        '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "Good Packet Start"))
        packetProgress := START_PACKET_RX_1
      else
        ProcessCameraError(localCharacter)
    START_PACKET_RX_1:
      expectedSizeRx := localCharacter
      '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "expectedSizeRx = "))
      '*0326b* Serial.Dec(USB_PORT_0, expectedSizeRx)
      packetProgress := SIZE_PACKET_RX_2

    SIZE_PACKET_RX_2:
      if localCharacter == CAMERA_DEVICE_ADDRESS_0X36
        dataRxCount := 1
        packetProgress := DEVICE_PACKET_RX_3
        '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "Good Device Address"))
        calculatedChecksum := localCharacter 'Checksum starts with deviced address (0X36).
      else
        ProcessCameraError(localCharacter)

    DEVICE_PACKET_RX_3:
      cameraClassRx := localCharacter
      '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "cameraClassRx = "))
      '*0326b* Serial.Hex(USB_PORT_0, cameraClassRx, 2)
      packetProgress := CLASS_PACKET_RX_4
      calculatedChecksum += localCharacter
      dataRxCount++
    CLASS_PACKET_RX_4:
      cameraSubclassRx := localCharacter
      '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "cameraSubclassRx = "))
      '*0326b* Serial.Hex(USB_PORT_0, cameraSubclassRx, 2)
      packetProgress := SUBCLASS_PACKET_RX_5
      calculatedChecksum += localCharacter
      dataRxCount++
    SUBCLASS_PACKET_RX_5:
      cameraFlagRx := localCharacter
      '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "cameraFlagRx = "))
      '*0326b* Serial.Hex(USB_PORT_0, cameraFlagRx, 2)
      if cameraFlagRx == NORMAL_FLAG_3
        normalFlagCount++
      elseif cameraFlagRx == ERROR_FLAG_4
        errorFlagCount++
      packetProgress := FLAG_PACKET_RX_6
      rxBufferIndex := 0
      calculatedChecksum += localCharacter
      dataRxCount++
    FLAG_PACKET_RX_6:
      rxData[rxBufferIndex++] := localCharacter
      {'*0326b* Serial.Str(USB_PORT_0, string(11, 13, "rxData["))
      Serial.Dec(USB_PORT_0, rxBufferIndex - 1)
      Serial.Str(USB_PORT_0, string("] = "))
      Serial.Dec(USB_PORT_0, rxData[rxBufferIndex - 1])   }'*0326b*

      calculatedChecksum += localCharacter
      dataRxCount++
      {'*0326b* Serial.Str(USB_PORT_0, string(11, 13, "dataRxCount = "))
      Serial.Dec(USB_PORT_0, dataRxCount)
      Serial.Str(USB_PORT_0, string(11, 13, "expectedSizeRx = "))
      Serial.Dec(USB_PORT_0, expectedSizeRx)    }'*0326b*
      if dataRxCount == expectedSizeRx

        packetProgress := DATA_PACKET_RX_7
        rxData[rxBufferIndex] := 0 'Terminate possible text with a zero.
    DATA_PACKET_RX_7:

      rxChecksum := localCharacter
      {'*0326b* Serial.Str(USB_PORT_0, string(11, 13, "calculatedChecksum = "))
      Serial.Dec(USB_PORT_0, calculatedChecksum)
      Serial.Str(USB_PORT_0, string(11, 13, "rxChecksum = "))
      Serial.Dec(USB_PORT_0, rxChecksum)       }'*0326b*

      if calculatedChecksum == rxChecksum
        packetProgress := CHECKSUM_PACKET_RX_8
      else
        ProcessCameraError(localCharacter)

    CHECKSUM_PACKET_RX_8:

      if localCharacter == PACKET_END_0XFF
        '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "Good end of packet."))
        '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "Start processing packet."))
        ProcessCameraPacket
        packetProgress := NONE_PACKET_RX_0
      else
        ProcessCameraError(localCharacter)

PRI ProcessCameraPacket | parameterIndex, localDataSize, localData, localIndex, localMaxIndex

  '*0326b* DebugPacketRx

  completeRxCount++
  '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "completeRxCount = "))
  '*0326b* Serial.Dec(USB_PORT_0, completeRxCount)
  parameterIndex := FingParameterFromClass(cameraClassRx, cameraSubclassRx)
  {'*0326b* Serial.Str(USB_PORT_0, string(11, 13, "ProcessCameraPacket | parameterIndex = "))
  Serial.Str(USB_PORT_0, FindString(@cameraDataTypeText, parameterIndex))

  Serial.Str(USB_PORT_0, string(11, 13, "ProcessCameraPacket | frozenCameraTxRequest = "))
  Serial.Str(USB_PORT_0, FindString(@cameraTxRequestText, frozenCameraTxRequest))
  Serial.Str(USB_PORT_0, string(11, 13, "programName = "))
  Serial.Str(USB_PORT_0, @programName)    }      '*0326b*


  localDataSize := expectedSizeRx - 4
  '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "localDataSize = "))
  '*0326b* Serial.Dec(USB_PORT_0, localDataSize)
  localMaxIndex := 0 #> localDataSize - 1 <# 3
  '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "localMaxIndex = "))
  '*0326b* Serial.Dec(USB_PORT_0, localMaxIndex)
  localData := 0
  repeat localIndex from 0 to localMaxIndex
    localData <<= 8
    localData +=  rxData[localIndex]

  '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "localData = "))
  '*0326b* Serial.Dec(USB_PORT_0, localData)

  case frozenCameraTxRequest
    NO_CAMERA_TX_REQUEST_0:
      Serial.Str(USB_PORT_0, string(9, 11, 13, "Why NO_CAMERA_TX_REQUEST_0?"))
    READ_CAMERA_TX_REQUEST_1:
      parametersFromRead[parameterIndex] := localData
      '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "parametersFromRead["))
      '*0326b* Serial.Str(USB_PORT_0, FindString(@cameraDataTypeText, parameterIndex))
      '*0326b* Serial.Str(USB_PORT_0, string("] = "))
      '*0326b* Serial.Dec(USB_PORT_0, parametersFromRead[parameterIndex])
      if parameterIndex ==  PALETTE_DATA_21
        targetPalette := localData
        '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "targetPalette = "))
        '*0326b* Serial.Str(USB_PORT_0, FindString(@paletteText, targetPalette))

    WRITE_CAMERA_TX_REQUEST_2:
      parametersFromWrite[parameterIndex] := localData
      '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "parametersFromWrite["))
      '*0326b* Serial.Str(USB_PORT_0, FindString(@cameraDataTypeText, parameterIndex))
      '*0326b* Serial.Str(USB_PORT_0, string("] = "))
      '*0326b* Serial.Dec(USB_PORT_0, parametersFromWrite[parameterIndex])
      'if parameterIndex == MODEL_DATA_1


  if parameterIndex == MODEL_DATA_1

    '*0326b* Serial.Str(USB_PORT_0, string(11, 13, "Camera Model = ", 34))
    '*0326b* SafeStr(USB_PORT_0, @rxData, localDataSize)
    '*0326b* Serial.Tx(USB_PORT_0, 34)
    modelDataSize := localDataSize
    bytemove(@modelDataBuffer, @rxData, localDataSize)
       {'*0326b*
  elseif parameterIndex ==  PALETTE_DATA_21
    Serial.Str(USB_PORT_0, string(11, 13, "palette = "))
    Serial.Str(USB_PORT_0, FindString(@paletteText, localData))
    'if



  elseif parameterIndex ==  MIRROR_DATA_22
    Serial.Str(USB_PORT_0, string(11, 13, "mirroring = "))
    Serial.Str(USB_PORT_0, FindString(@mirroringText, localData))
    }'*0326b*

PRI DebugPacketRx | dataIndex, bytesOfData

  'expectedSizeRx, cameraClassRx, cameraSubclassRx, cameraFlagRx
  'long dataRxCount, rxBufferIndex, dataTxCount, calculatedChecksum, rxChecksum
  Serial.Str(USB_PORT_0, string(11, 13, "DebugPacket"))
  Serial.Str(USB_PORT_0, string(11, 13, "expectedSizeRx = "))
  Serial.Dec(USB_PORT_0, expectedSizeRx)
  Serial.Str(USB_PORT_0, string(11, 13, "cameraClassRx = "))
  Serial.Dec(USB_PORT_0, cameraClassRx)
  Serial.Str(USB_PORT_0, string(" = $"))
  Serial.Hex(USB_PORT_0, cameraClassRx, 2)
  Serial.Str(USB_PORT_0, string(11, 13, "cameraSubclassRx = "))
  Serial.Dec(USB_PORT_0, cameraSubclassRx)
  Serial.Str(USB_PORT_0, string(" = $"))
  Serial.Hex(USB_PORT_0, cameraSubclassRx, 2)

  Serial.Str(USB_PORT_0, string(11, 13, "cameraFlagRx = "))
  Serial.Dec(USB_PORT_0, cameraFlagRx)
  Serial.Str(USB_PORT_0, string(" = "))
  Serial.Str(USB_PORT_0, FindString(@cameraFlagText, cameraFlagRx))


  dataIndex := 0
  bytesOfData := expectedSizeRx - 4
  Serial.Str(USB_PORT_0, string(11, 13, "bytesOfData = "))
  Serial.Dec(USB_PORT_0, bytesOfData)
  if bytesOfData > 0 and bytesOfData < MAX_PACKET_SIZE_RX_128
    Serial.Str(USB_PORT_0, string(11, 13, "received data: "))
    repeat bytesOfData
      if dataIndex
        Serial.Str(USB_PORT_0, string(", "))

      Serial.Str(USB_PORT_0, string("rxData["))
      Serial.Dec(USB_PORT_0, dataIndex)
      Serial.Str(USB_PORT_0, string("] = "))
      Serial.Dec(USB_PORT_0, rxData[dataIndex++])

  if cameraFlagRx == NORMAL_FLAG_3
    Serial.Str(USB_PORT_0, string(11, 13, "normalFlagCount = "))
    Serial.Dec(USB_PORT_0, normalFlagCount)
  elseif cameraFlagRx == ERROR_FLAG_4
    Serial.Str(USB_PORT_0, string(11, 13, "errorFlagCount = "))
    Serial.Dec(USB_PORT_0, errorFlagCount)
  else
    Serial.Str(USB_PORT_0, string(9, 11, 13, "WHY? cameraFlagRx = "))
    Serial.Dec(USB_PORT_0, cameraFlagRx)
    Serial.Str(USB_PORT_0, string(" = "))
    Serial.Str(USB_PORT_0, FindString(@cameraFlagText, cameraFlagRx))

PRI FingParameterFromClass(localClass, localSubclass) : parameterIndex | localIndex

  localClass <<= 8
  localClass |= localSubclass

  repeat localIndex from NO_DATA_0 to INIT_STATE_REPLY_DATA_24
    if classAndSubclass[localIndex] == localClass
      parameterIndex := localIndex
      quit

PUB TxToCamera | localIndex

  {'*0326b* Serial.Str(USB_PORT_0, string(11, 13, "TxToCamera, txSize = "))
  Serial.Dec(USB_PORT_0, txSize)
  Serial.Str(USB_PORT_0, string(11, 13, "cameraClassTx = "))
  Serial.Dec(USB_PORT_0, cameraClassTx)
  Serial.Str(USB_PORT_0, string(" = $"))
  Serial.Hex(USB_PORT_0, cameraClassTx, 2)
  Serial.Str(USB_PORT_0, string(11, 13, "cameraSubclassTx = "))
  Serial.Dec(USB_PORT_0, cameraSubclassTx)
  Serial.Str(USB_PORT_0, string(" = $"))
  Serial.Hex(USB_PORT_0, cameraSubclassTx, 2)
  Serial.Str(USB_PORT_0, string(11, 13, "cameraFlagTx = "))
  Serial.Dec(USB_PORT_0, cameraFlagTx)
  Serial.Str(USB_PORT_0, string(11, 13, "txData[0] = "))
  Serial.Dec(USB_PORT_0, txData[0])
   }'*0326b*
  Camera.Char(PACKET_START_0XF0)

  Camera.Char(txSize)

  Camera.Char(CAMERA_DEVICE_ADDRESS_0X36)
  txChecksum := CAMERA_DEVICE_ADDRESS_0X36
  txSize--
  Camera.Char(cameraClassTx)
  txChecksum += cameraClassTx
  txSize--
  Camera.Char(cameraSubclassTx)
  txChecksum += cameraSubclassTx
  txSize--
  Camera.Char(cameraFlagTx)
  txChecksum += cameraFlagTx
  txSize--

  localIndex := 0
  repeat while txSize
    Camera.Char(txData[localIndex])
    txChecksum += txData[localIndex]
    localIndex++
    txSize--
  Camera.Char(txChecksum)
  Camera.Char(PACKET_END_0XFF)

PUB FindString(firstStr, stringIndex)
'' Finds start address of one string in a list
'' of string. "firstStr" is the address of
'' string #0 in the list. "stringIndex"
'' indicates which of the strings in the list
'' the method is to find.

  result := firstStr
  repeat while stringIndex
    repeat while byte[result++]
    stringIndex--

PUB SafeStr(port, localString, charactersToDisplay) | localCharacter

  repeat charactersToDisplay
    localCharacter := byte[localString++]
    SafeTx(port, localCharacter)

PUB SafeTx(port, localCharacter)

  if localCharacter > 31 and localCharacter < 127
    Serial.Tx(port, localCharacter)
  else
    Serial.Tx(port, "<")
    Serial.Tx(port, "$")
    Serial.Hex(port, localCharacter, 2)
    Serial.Tx(port, ">")

DAT

rxPortText              byte "ELRS_CONTROL_RX_PORT_0", 0
                        byte "ELRS_TELEMETRY_RX_PORT_1", 0

usbPortText             byte "USB_PORT_0", 0

channelText             byte "roll", 0
                        byte "pitch", 0
                        byte "throttle", 0
                        byte "yaw", 0
                        byte "arm", 0
                        byte "mode", 0
                        byte "seven", 0
                        byte "eight", 0
                        byte "nine", 0
                        byte "ten", 0
                        byte "eleven", 0
                        byte "twelve", 0
                        byte "thirteen", 0
                        byte "fourteen", 0
                        byte "fifteen", 0
                        byte "sixteen", 0

packetProgressText      byte "NONE_PACKET_RX_0", 0
                        byte "START_PACKET_RX_1", 0
                        byte "SIZE_PACKET_RX_2", 0
                        byte "DEVICE_PACKET_RX_3", 0
                        byte "CLASS_PACKET_RX_4", 0
                        byte "SUBCLASS_PACKET_RX_5", 0
                        byte "FLAG_PACKET_RX_6", 0
                        byte "DATA_PACKET_RX_7", 0
                        byte "CHECKSUM_PACKET_RX_8", 0
                        byte "END_PACKET_RX_9", 0
                        byte "PROCESS_PACKET_RX_10", 0

{expectedCameraDataText  byte "NONE_EXPECTED_0", 0
                        byte "MODEL_EXPECTED_1", 0
                        byte "WRITE_PALETTE_NONE_EXPECTED_2", 0
                        byte "PALETTE_EXPECTED_3", 0  }

paletteText             byte "WHITE_HOT_PALETTE_0", 0
                        byte "BLACK_HOT_PALETTE_1", 0
                        byte "FUSION1_PALETTE_2", 0
                        byte "RAINBOW_PALETTE_3", 0
                        byte "FUSION2_PALETTE_4", 0
                        byte "IRON_RED1_PALETTE_5", 0
                        byte "IRON_RED2_PALETTE_6", 0
                        byte "DARK_BROWN_PALETTE_7", 0
                        byte "COLOR1_PALETTE_8", 0
                        byte "COLOR2_PALETTE_9", 0
                        byte "ICE_FIRE_PALETTE_10", 0
                        byte "RAIN_PALETTE_11", 0
                        byte "GREEN_HOT_PALETTE_12", 0
                        byte "RED_HOT_PALETTE_13", 0
                        byte "DEEP_BLUE_PALETTE_14", 0

cameraFlagText          byte "WRITE_FLAG_0", 0
                        byte "READ_FLAG_1", 0
                        byte "UNUSED_2", 0
                        byte "NORMAL_FLAG_3", 0
                        byte "ERROR_FLAG_4", 0

switchStateText         byte "LOW_SWITCH_STATE_0", 0
                        byte "MIDDLE_SWITCH_STATE_1", 0
                        byte "HIGH_SWITCH_STATE_2", 0

cameraTxRequestText     byte "NO_CAMERA_TX_REQUEST_0", 0
                        byte "READ_CAMERA_TX_REQUEST_1", 0
                        byte "WRITE_CAMERA_TX_REQUEST_2", 0

expectedUserInputText   byte "READY_USER_EXPECTED_0", 0
                        byte "READ_USER_EXPECTED_1", 0
                        byte "WAIT_FOR_READ_USER_EXPECTED_2", 0
                        byte "DATA_INPUT_USER_EXPECTED_3", 0
                        byte "WRITE_USER_EXPECTED_4", 0
                        byte "WAIT_FOR_WRITE_USER_EXPECTED_5", 0

mirroringText           byte "NO_MIRRORING_0", 0
                        byte "CENTRAL_MIRRORING_1(Normal left & right mirror.)", 0
                        byte "LEFT_AND_RIGHT_MIRRORING_2(Mirror and rotated 180 degrees.)", 0
                        byte "UP_AND_DOWN_MIRRORING_3(Rotate 180 degrees.)", 0

cameraDataTypeText      byte "NO_DATA_0", 0
                        byte "MODEL_DATA_1", 0
                        byte "FPGA_VERSION_DATA_2", 0
                        byte "FPGA_TIME_DATA_3", 0
                        byte "SOFTWARE_VERSION_DATA_4", 0
                        byte "SOFTWARE_TIME_DATA_5", 0
                        byte "CAL_TIME_DATA_6", 0
                        byte "ISP_DATA_7", 0
                        byte "SAVE_DATA_8", 0
                        byte "RESET_DATA_9", 0
                        byte "SHUTTER_DATA_10", 0
                        byte "BACKGROUND_DATA_11", 0
                        byte "VIGNETTING_DATA_12", 0
                        byte "AUTO_SHUTTER_DATA_13", 0
                        byte "AUTO_INTERVAL_DATA_14", 0
                        byte "DEFECTIVE_PIXEL_DATA_15", 0
                        byte "BRIGHTNESS_DATA_16", 0
                        byte "CONTRAST_DATA_17", 0
                        byte "ENHANCEMENT_DATA_18", 0
                        byte "STATIC_DENOISING_DATA_19", 0
                        byte "DYNAMIC_DENOISING_DATA_20", 0
                        byte "PALETTE_DATA_21", 0
                        byte "MIRROR_DATA_22", 0
                        byte "INIT_STATE_REQUEST_DATA_23", 0
                        byte "INIT_STATE_REPLY_DATA_24", 0


modelDataBuffer         byte 0[MAX_MODEL_CHARACTERS_16]
modelDataSize           long 0-0
classAndSubclass        long $0000
                        long $7402
                        long $7403
                        long $7404
                        long $7405
                        long $7406
                        long $7408
                        long $740C
                        long $7410
                        long $740F
                        'SHUTTER_DATA_10
                        long $7C02
                        long $7C03
                        long $7C0C
                        long $7C04
                        long $7C05
                        'DEFECTIVE_PIXEL_DATA_15
                        long $781A
                        long $7802
                        long $7803
                        long $7810
                        long $7815
                        long $7816
                        'PALETTE_DATA_21
                        long $7820
                        long $7011
                        'INIT_STATE_REQUEST_DATA_23
initStateRequest        long $7C14

initStateFeedback       long $7D06

readAfterWriteFlag      long true

parametersFromRead      long NOT_A_NUMBER[NUMBER_OF_DATA_TYPES_25]
parametersFromWrite     long NOT_A_NUMBER[NUMBER_OF_DATA_TYPES_25]