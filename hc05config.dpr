{ --------------------------------------------------------------------------
  A tool to easily configure HC-05 wireless modules.
  Currently Raspberry Pi / Linux only.

  Yup, this code is awful and thrown together. Who cares for now, it works!
  AND NO I DO NOT CORRECTLY INTERPRET AT COMMANDS. AGAIN, it does not matter (yet)

  Copyright (c) Michael Nixon 2017.
  Distributed under the MIT license, please see the LICENSE file.
  -------------------------------------------------------------------------- }
program hc05config;

uses baseunix, unix, termio, classes, sysutils;

{ --------------------------------------------------------------------------
  BLOCKING: Wait for a data byte and return it
  -------------------------------------------------------------------------- }
function WaitForByte(comhandle: thandle): byte;
const
  TIMEOUT_SECS = 5;
var
  fdset: TFDSet;
  b: byte;
  timeval: ptimeval;
  timev: ttimeval;
  i: longint;
begin
  timev.tv_usec := 0;
  timev.tv_sec := 5;
  timeval := @timev;
  fpfd_zero(fdset);
  fpfd_set(comhandle, fdset);
  i := fpselect(comhandle + 1, @fdset, nil, nil, timeval);
  if i = 0 then begin
    writeln('Error: Read timeout (the module might be in data mode)');
    halt;
  end else if i < 0 then begin
    writeln('Error: select() failed');
    halt;
  end;
  fileread(comhandle, b, sizeof(byte));
  result := b;
end;

{ --------------------------------------------------------------------------
  BLOCKING: Wait for a line from the UART and return it (without CRLF)
  -------------------------------------------------------------------------- }
function GetLine(comhandle: thandle): ansistring;
var
  buffer: ansistring;
  b: byte;
begin
  buffer := '';
  repeat
    b := WaitForByte(comhandle);
    if ((b = 13) or (b = 10)) and (length(buffer) <> 0) then begin
      { Got a complete line! }
      result := buffer;
      exit;
    end;
    if (b <> 13) and (b <> 10) then begin
      buffer := buffer + chr(b);
    end;
  until false;
end;

{ --------------------------------------------------------------------------
  BLOCKING: Write a line to the UART (with CRLF)
  -------------------------------------------------------------------------- }
procedure WriteLine(comhandle: thandle; s: ansistring);
var
  tempstring: ansistring;
begin
  tempstring := s + #13 + #10;
  filewrite(comhandle, tempstring[1], length(tempstring));
  tcdrain(comhandle);
end;

{ --------------------------------------------------------------------------
  Return text after ':' only
  -------------------------------------------------------------------------- }
function AfterColon(s: ansistring): string;
var
  i: integer;
begin
  i := pos(':', s);
  if (i < 2) or (i >= length(s)) then begin
    writeln('Error: Malformed response: ' + s);
    halt;
  end;
  result := copy(s, i + 1, length(s) - i);
end;

{ --------------------------------------------------------------------------
  Command: Get module info
  -------------------------------------------------------------------------- }
procedure CommandInfo(comhandle: thandle);
const
  COMMAND_ERROR = 'Error: Module did not accept command';
  ERRORMSG = 'Error: Unexpected response: ';
  AT_OK = 'OK';
var
  mod_version: ansistring;
  mod_password: ansistring;
  mod_baud: ansistring;
  mod_state: ansistring;
  mod_role: ansistring;
  mod_addr: ansistring;
  mod_cmode: ansistring;
  mod_authed_count: ansistring;
  mod_most_recent_address: ansistring;
  mod_bind: ansistring;
begin
  WriteLine(comhandle, 'AT+VERSION?');
  mod_version := AfterColon(GetLine(comhandle));
  sleep(50);
  tcflush(comhandle, tciflush);

  WriteLine(comhandle, 'AT+PSWD?');
  mod_password := AfterColon(GetLine(comhandle));
  sleep(50);
  tcflush(comhandle, tciflush);

  WriteLine(comhandle, 'AT+UART?');
  mod_baud := AfterColon(GetLine(comhandle));
  sleep(50);
  tcflush(comhandle, TCIFLUSH);

  WriteLine(comhandle, 'AT+STATE?');
  mod_state := AfterColon(GetLine(comhandle));
  sleep(50);
  tcflush(comhandle, TCIFLUSH);

  WriteLine(comhandle, 'AT+ROLE?');
  mod_role := AfterColon(GetLine(comhandle));
  sleep(50);
  tcflush(comhandle, TCIFLUSH);

  WriteLine(comhandle, 'AT+ADDR?');
  mod_addr := AfterColon(GetLine(comhandle));
  sleep(50);
  tcflush(comhandle, TCIFLUSH);

  WriteLine(comhandle, 'AT+CMODE?');
  mod_cmode := AfterColon(GetLine(comhandle));
  sleep(50);
  tcflush(comhandle, TCIFLUSH);

  WriteLine(comhandle, 'AT+ADCN?');
  mod_authed_count := AfterColon(GetLine(comhandle));
  sleep(50);
  tcflush(comhandle, TCIFLUSH);

  WriteLine(comhandle, 'AT+MRAD?');
  mod_most_recent_address := AfterColon(GetLine(comhandle));
  sleep(50);
  tcflush(comhandle, TCIFLUSH);

  WriteLine(comhandle, 'AT+BIND?');
  mod_bind := AfterColon(GetLine(comhandle));
  sleep(500);
  tcflush(comhandle, TCIFLUSH);

  writeln('Firmware version                              : ' + mod_version);
  writeln('Device state                                  : ' + mod_state);
  writeln('Bluetooth address                             : ' + mod_addr);
  writeln('Password / passcode / PIN                     : ' + mod_password);
  writeln('UART (baud rate, extra stop bits, parity bit) : ' + mod_baud);
  if mod_role = '0' then begin
    writeln('Master / slave mode (SPP)                     : SLAVE');
  end else begin
    writeln('Master / slave mode (SPP)                     : MASTER');
  end;
  writeln('Connection mode (CMODE)                       : ' + mod_cmode);
  writeln('Number of authenticated devices               : ' + mod_authed_count);
  writeln('Most recent bluetooth remote peer address     : ' + mod_most_recent_address);
  writeln('Configured bind address (if master)           : ' + mod_bind);
end;

{ --------------------------------------------------------------------------
  Reset the device to factory settings
  -------------------------------------------------------------------------- }
procedure CommandReset(comhandle: thandle);
const
  COMMAND_ERROR = 'Error: Module did not accept command';
  ERRORMSG = 'Error: Unexpected response: ';
  AT_OK = 'OK';
begin
  writeln('Resetting module to factory default settings');
  WriteLine(comhandle, 'AT+ORGL');
  sleep(1000);
  tcflush(comhandle, TCIFLUSH);
  writeln('Clearing any paired devices');
  WriteLine(comhandle, 'AT+RMAAD');
  sleep(1000);
  tcflush(comhandle, TCIFLUSH);
  writeln('Complete.');
end;

{ --------------------------------------------------------------------------
  Reboot the module
  -------------------------------------------------------------------------- }
procedure CommandReboot(comhandle: thandle);
const
  COMMAND_ERROR = 'Error: Module did not accept command';
  ERRORMSG = 'Error: Unexpected response: ';
  AT_OK = 'OK';
begin
  writeln('Rebooting/resetting the module (this will not have the intended effect if the module has a KEY pin).');
  WriteLine(comhandle, 'AT+RESET');
  sleep(1000);
  tcflush(comhandle, TCIFLUSH);
  writeln('Complete. The module should now be in data mode.');
end;

{ --------------------------------------------------------------------------
  Configure this module as a slave module.
  paramstr(3) is the PIN.
  -------------------------------------------------------------------------- }
procedure CommandSetSlave(comhandle: thandle);
const
  COMMAND_ERROR = 'Error: Module did not accept command';
  CONFIG_ERROR = 'Error: Module could not be configured correctly';
  ERRORMSG = 'Error: Unexpected response: ';
  AT_OK = 'OK';
var
  pin: ansistring;
  addr: ansistring;
begin
  pin := paramstr(3);
  writeln('Configuring the module as a slave device with the PIN code ' + pin);

  WriteLine(comhandle, 'AT+ORGL');
  sleep(1000);
  tcflush(comhandle, TCIFLUSH);

  WriteLine(comhandle, 'AT+RMAAD');
  sleep(50);
  tcflush(comhandle, TCIFLUSH);

  WriteLine(comhandle, 'AT+ADDR?');
  addr := AfterColon(GetLine(comhandle));
  sleep(50);
  tcflush(comhandle, TCIFLUSH);

  WriteLine(comhandle, 'AT+UART=9600,0,0');
  {if GetLine(comhandle) <> AT_OK then begin
    writeln(COMMAND_ERROR);
    halt;
  end;}
  GetLine(comhandle);

  WriteLine(comhandle, 'AT+PSWD=' + pin);
  if GetLine(comhandle) <> AT_OK then begin
    writeln(COMMAND_ERROR);
    halt;
  end;

  WriteLine(comhandle, 'AT+ROLE=0');
  if GetLine(comhandle) <> AT_OK then begin
    writeln(COMMAND_ERROR);
    halt;
  end;

  WriteLine(comhandle, 'AT+CMODE=0');
  if GetLine(comhandle) <> AT_OK then begin
    writeln(COMMAND_ERROR);
    halt;
  end;

  writeln('Confirming the configuration...');

  WriteLine(comhandle, 'AT+UART?');
  if AfterColon(GetLine(comhandle)) <> '9600,0,0' then begin
    writeln(CONFIG_ERROR);
    halt;
  end;
  sleep(50);
  tcflush(comhandle, TCIFLUSH);

  WriteLine(comhandle, 'AT+ROLE?');
  if AfterColon(GetLine(comhandle)) <> '0' then begin
    writeln(CONFIG_ERROR);
    halt;
  end;
  sleep(50);
  tcflush(comhandle, TCIFLUSH);

  WriteLine(comhandle, 'AT+PSWD?');
  if AfterColon(GetLine(comhandle)) <> pin then begin
    writeln(CONFIG_ERROR);
    halt;
  end;
  sleep(50);
  tcflush(comhandle, TCIFLUSH);

  writeln('Complete.');
  writeln('Bluetooth device address to use to pair with the master: ' + addr);
end;

{ --------------------------------------------------------------------------
  Configure this module as a master module.
  paramstr(3) is the PIN.
  paramstr(4) is the bluetooth address to pair with.
  -------------------------------------------------------------------------- }
procedure CommandSetMaster(comhandle: thandle);
const
  COMMAND_ERROR = 'Error: Module did not accept command';
  CONFIG_ERROR = 'Error: Module could not be configured correctly';
  ERRORMSG = 'Error: Unexpected response: ';
  AT_OK = 'OK';
var
  s: ansistring;
  pin: ansistring;
  addr: ansistring;
  i: longint;
begin
  pin := paramstr(3);
  addr := paramstr(4);
  writeln('Configuring the module as a master device with the PIN code ' + pin + ' pairing to device ' + addr);

  WriteLine(comhandle, 'AT+ORGL');
  sleep(1000);
  tcflush(comhandle, TCIFLUSH);

  WriteLine(comhandle, 'AT+RMAAD');
  sleep(50);
  tcflush(comhandle, TCIFLUSH);

  WriteLine(comhandle, 'AT+UART=9600,0,0');
  {if GetLine(comhandle) <> AT_OK then begin
    writeln(COMMAND_ERROR);
    halt;
  end;}
  GetLine(comhandle);

  WriteLine(comhandle, 'AT+PSWD=' + pin);
  if GetLine(comhandle) <> AT_OK then begin
    writeln(COMMAND_ERROR);
    halt;
  end;

  WriteLine(comhandle, 'AT+ROLE=1');
  if GetLine(comhandle) <> AT_OK then begin
    writeln(COMMAND_ERROR);
    halt;
  end;

  WriteLine(comhandle, 'AT+CMODE=0');
  if GetLine(comhandle) <> AT_OK then begin
    writeln(COMMAND_ERROR);
    halt;
  end;

  s := addr;
  for i := 1 to length(s) do begin
    if s[i] = ':' then s[i] := ',';
  end;
  WriteLine(comhandle, 'AT+BIND=' + s);
  if GetLine(comhandle) <> AT_OK then begin
    writeln(COMMAND_ERROR);
    halt;
  end;

  writeln('Confirming the configuration...');

  WriteLine(comhandle, 'AT+UART?');
  if AfterColon(GetLine(comhandle)) <> '9600,0,0' then begin
    writeln(CONFIG_ERROR);
    halt;
  end;
  sleep(50);
  tcflush(comhandle, TCIFLUSH);

  WriteLine(comhandle, 'AT+ROLE?');
  if AfterColon(GetLine(comhandle)) <> '1' then begin
    writeln(CONFIG_ERROR);
    halt;
  end;
  sleep(50);
  tcflush(comhandle, TCIFLUSH);

  WriteLine(comhandle, 'AT+PSWD?');
  if AfterColon(GetLine(comhandle)) <> pin then begin
    writeln(CONFIG_ERROR);
    halt;
  end;
  sleep(50);
  tcflush(comhandle, TCIFLUSH);

  WriteLine(comhandle, 'AT+CMODE?');
  if AfterColon(GetLine(comhandle)) <> '0' then begin
    writeln(CONFIG_ERROR);
    halt;
  end;
  sleep(50);
  tcflush(comhandle, TCIFLUSH);

  WriteLine(comhandle, 'AT+BIND?');
  if AfterColon(GetLine(comhandle)) <> addr then begin
    writeln(CONFIG_ERROR);
    halt;
  end;
  sleep(50);
  tcflush(comhandle, TCIFLUSH);

  writeln('Complete.');
end;

{ --------------------------------------------------------------------------
  Set the communications baud rate on the TX/RX pins.
  -------------------------------------------------------------------------- }
procedure CommandSetDataBaudRate(comhandle: thandle);
const
  COMMAND_ERROR = 'Error: Module did not accept command';
  CONFIG_ERROR = 'Error: Module could not be configured correctly';
  ERRORMSG = 'Error: Unexpected response: ';
  AT_OK = 'OK';
var
  baud: ansistring;
begin
  baud := paramstr(3);
  writeln('Changing the baud rate to ' + baud + ' with 1 stop bit and no parity');

  WriteLine(comhandle, 'AT+UART=' + baud + ',0,0');
  {if GetLine(comhandle) <> AT_OK then begin
    writeln(COMMAND_ERROR);
    halt;
  end;}
  GetLine(comhandle);

  writeln('Confirming the configuration...');

  WriteLine(comhandle, 'AT+UART?');
  if AfterColon(GetLine(comhandle)) <> baud + ',0,0' then begin
    writeln(CONFIG_ERROR);
    halt;
  end;
  sleep(50);
  tcflush(comhandle, TCIFLUSH);

  writeln('Complete.');
end;

{ --------------------------------------------------------------------------
  Perform a loopback test
  -------------------------------------------------------------------------- }
procedure CommandLoopBackTest(comhandle: thandle);
begin
  writeln('Starting an endless loopback test.');
  writeln('The current date and time will be sent, and the program will wait for a response and display it.');
  writeln('Press ctrl+c to stop.');
  writeln('------------------------------------');
  repeat
    WriteLine(comhandle, datetimetostr(now));
    writeln('Received: ' + GetLine(comhandle));
    sleep(100);
  until false;
end;

{ --------------------------------------------------------------------------
  Main program
  -------------------------------------------------------------------------- }
var
  s: ansistring;
  comsettings: termios;
  comhandle: thandle;
  cmd: ansistring;
  devicefilename: ansistring;
begin
  if paramCount < 2 then begin
    writeln('HC-05 configuration program, (c) Michael Nixon 2017.');
    writeln('Usage: hc05config <port> <command> <command parameters>');
    writeln;
    writeln('Before doing anything, make sure the module is in programming mode!');
    writeln('If it has an LED, it should be blinking slowly.');
    writeln;
    writeln('port: The serial port device to use. For a Raspberry Pi, this is usually /dev/ttyAMA0 - however');
    writeln('      if you are using a Pi 3, things are different (TODO)');
    writeln;
    writeln('command: Specify one of:');
    writeln('  info - display information about the HC-05 module, such as the current operating mode');
    writeln('  reset - reset the module to factory default settings. You usually do not need to use this.');
    writeln('  setslave <passcode> - set the device to be the SLAVE device and return the bluetooth adddress.');
    writeln('    passcode: A 4 digit numeric passcode. Both modules MUST use the same passcode to pair.');
    writeln('    * NOTE: The bluetooth address is returned. You will need it to configure the master module.');
    writeln('  setmaster <passcode> <slaveaddress> - set the device to be the MASTER device.');
    writeln('    passcode: A 4 digit numeric passcode. Both modules MUST use the same passcode to pair.');
    writeln('    slaveaddress: The slave address returned by running the setslave command on the other module.');
    writeln('  setdatabaudrate <baud> - set the baud rate to use when in data mode on the TX/RX pins');
    writeln('    baud: The baud rate to use in data (normal) mode. This tool will configure');
    writeln('          the module to use a baud rate of 9600 by default. Both modules should have the');
    writeln('          same baud rate set or you risk overrunning the buffer in the device and losing data.');
    writeln('          1 stop bit and no parity is configured.');
    writeln('  reboot - reboot the module (for modules with buttons rather than KEY pins, this puts them into data mode)');
    writeln('  loopbacktest <baud> - performs a simple loopback test to see if your paired modules are working.');
    writeln('    baud: The baud rate you configured for data mode on the TX/RX pins');
    writeln('    To use this:');
    writeln('      - connect one module to your Pi normally - not in programming mode (no KEY pin or button press)');
    writeln('      - for the other module, connect TX and RX together and power it up (a breadboard is a good thing!)');
    writeln('      - wait for the LEDs on both modules to occasionally blink (the link is up). Now run this command');
    writeln;
    writeln('After configuring a module, a power cycle is needed to enter data mode (usually). This is convenient,');
    writeln('because it means you can use the <setslave> or <setmaster> command followed by <setdatabaudrate>.');
    exit;
  end;

  devicefilename := paramstr(1);
  cmd := lowercase(paramstr(2));
  if not fileexists(devicefilename) then begin
    writeln('Error: The device ' + devicefilename + ' does not exist.');
    exit;
  end;

  write('Opening the serial device... ');
  { Linux specific, configure the serial device. The settings when the module is in programming mode are:
    Baud rate: 38400
    Bits: 8
    Stop bits: 1
    Parity: None
    Flow control: None
    Yes this is all ugly and hardcoded to get it working in a hurry.
  }

  { Try to open the port }
  comhandle := thandle(fpopen(devicefilename, O_RDWR or O_SYNC or O_NOCTTY));
  if comhandle < 0 then begin
    writeln('failed');
    writeln('Error: Failed to open the serial device. Is the name correct?');
    exit;
  end;

  { Setup serial settings }
  { Get current serial port settings }
  if tcgetattr(comhandle, comsettings) < 0 then begin
    writeln('failed');
    writeln('Error: tcgetattr() failed');
    exit;
  end;

  { We want raw comms }
  cfmakeraw(comsettings);

  { Yes, this code is awful! Junk. TODO: Make it sensible }
  { Set baudrate }
  if cmd <> 'loopbacktest' then begin
    cfsetospeed(comsettings, B38400);
    cfsetispeed(comsettings, B38400);
  end else begin
    if paramstr(3) = '9600' then begin
      cfsetospeed(comsettings, B9600);
      cfsetispeed(comsettings, B9600);
    end else if paramstr(3) = '38400' then begin
      cfsetospeed(comsettings, B38400);
      cfsetispeed(comsettings, B38400);
    end else if paramstr(3) = '115200' then begin
      cfsetospeed(comsettings, B115200);
      cfsetispeed(comsettings, B115200);
    end else begin
      writeln('Error: Bad baud rate');
      exit;
    end;
  end;

  { Ignore modem controls }
  comsettings.c_cflag := comsettings.c_cflag or (CLOCAL or CREAD);
  { 8 bit character mode }
  comsettings.c_cflag := comsettings.c_cflag and (not CSIZE);
  comsettings.c_cflag := comsettings.c_cflag or CS8;
  { No parity bit }
  comsettings.c_cflag := comsettings.c_cflag and (not PARENB);
  { 1 stop bit }
  comsettings.c_cflag := comsettings.c_cflag and (not CSTOPB);
  { No hardware flow control }
  comsettings.c_cflag := comsettings.c_cflag and (not CRTSCTS);
  { HUPCL seems to be needed to avoid port hangs }
  comsettings.c_cflag := comsettings.c_cflag or HUPCL;

  { Setup for non-canonical mode }
  comsettings.c_iflag := comsettings.c_iflag and (not (IGNBRK or BRKINT or PARMRK or ISTRIP or INLCR or IGNCR or ICRNL or IXON));
  comsettings.c_iflag := comsettings.c_iflag and (not (ECHO or ECHONL or ICANON or ISIG or IEXTEN));
  comsettings.c_oflag := comsettings.c_oflag and (not OPOST);

  { Fetch bytes as they become available }
  comsettings.c_cc[VMIN] := 1;
  comsettings.c_cc[VTIME] := 1;

  { Apply settings }
  if tcsetattr(comhandle, TCSANOW, comsettings) <> 0 then begin
    writeln('Error: tcsetattr() failed');
    exit;
  end;

  { Make sure the port is ON }
  tcflow(comhandle, TCOON);

  { Flush everything }
  tcflush(comhandle, TCIOFLUSH);

  if cmd <> 'loopbacktest' then begin
    { First send an empty command anyway incase the module has received some garbage }
    WriteLine(comhandle, 'AT');
    sleep(500);
    tcflush(comhandle, TCIFLUSH);
    writeln('OK');
    write('Checking if the module is responding... ');
    WriteLine(comhandle, 'AT');
    s := GetLine(comhandle);
    if s <> 'OK' then begin
      writeln('failed');
      writeln('Error: Unexpected response: ' + s);
      exit;
    end;
  end;
  writeln('OK');

  if cmd = 'info' then begin
    CommandInfo(comhandle);
  end else if cmd = 'reboot' then begin
    CommandReboot(comhandle);
  end else if cmd = 'reset' then begin
    CommandReset(comhandle);
  end else if cmd = 'setslave' then begin
    if paramcount < 3 then begin
      writeln('Error: You need to specify the passcode / PIN');
      exit;
    end;
    { TODO: Should verify the passcode is a sensible one }
    CommandSetSlave(comhandle);
  end else if cmd = 'setmaster' then begin
    if paramcount < 4 then begin
      writeln('Error: You need to specify the passcode / PIN and slave bluetooth address');
      exit;
    end;
    { TODO: Should verify the passcode is a sensible one }
    CommandSetMaster(comhandle);
  end else if cmd = 'setdatabaudrate' then begin
    if paramcount < 3 then begin
      writeln('Error: You need to specify the baud rate');
      exit;
    end;
    { TODO: Should verify the baud rate is a sensible one }
    CommandSetDataBaudRate(comhandle);
  end else if cmd = 'loopbacktest' then begin
    CommandLoopBackTest(comhandle);
  end else begin
    writeln('Invalid command. Please run this program without any parameters for instructions.');
    exit;
  end;

  { Clean up }
  fpclose(comhandle);
end.
