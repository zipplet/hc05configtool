# hc05configtool
A tool for configuring HC-05 wireless modules easily.

## Issues

* This only works on a Linux computer (USB Serial to 3.3V TTL adaptor) or Raspberry Pi right now __(make sure the TX/RX pins are really 3.3V or the module may be destroyed)__
* The code is terrible, and does not actually comply with the AT command spec properly; that will change.
* No windows support yet. Coming soon, perhaps even a nice GUI.
* At some point, I'll add an Arduino version. You would connect 2 modules to the Arduino, and it would pair them automatically for you using a pseudorandom PIN code.

## Eh? What's this?
There is a common wireless module used by hobbyists when building things that need wireless communication locally between each other called the "HC-05" (there is also a variant called the "HC-06" but I do not have any).

If you have not heard of these before, try searching for "hc-05 rs232" on Amazon, eBay or similar and you shall see many of them for sale - typically shipped from China.

Once they are configured they are nice - power up both modules and very quickly establish a virtual serial link at TTL voltage levels. Temporarily power cycle one and it will reconnect. You can even have multiple projects using these modules in the same room, and they will connect to the correct modules acting like virtual serial cables. Small amounts of packet loss are tolerated by the module and data gets retransmitted automatically - very nice. As they use bluetooth the communications range is not extreme, but for most projects they are a good fit.

They are perfect for things like microcontrollers / Arduino / Raspberry Pi. They use bluetooth, but hide all of that from you. They tend to come pre-soldered onto a breakout board that just exposes TX, RX, power, ground, sometimes a "KEY" pin (if not a button instead) and often a couple of other pins for you to determine if they have established a link or not. 

The problem is they come unconfigured. Configuring them is an absolute pain. You have to put them into programming mode, then send a specific sequence of commands to both modules before they will pair with each other. Get it wrong and you can make it very insecure or just end up banging your head against the desk in frustration.

## How do I use it?
__At the moment, only Linux is supported (including the Raspberry Pi - which is convenient as it the Pi's UART is 3.3V TTL); Windows support will come later__

__To use this with a PC, you need Linux (if you have a Windows or Mac machine just use VirtualBox, install Linux, connect a USB serial to 3.3V TTL adaptor to your VM and bind it to the VM - I have tested this and it works fine)__

All you need to do is:
* Get a pair of modules (and for now, a Raspberry Pi or Linux computer/VM - later I will support Windows
* Pi users: Disable the serial console on your Raspberry Pi (sudo raspi-config), but __do not turn the Pi off yet__
* Pi users: Edit /boot/config.txt and make sure that you change __enable_uart=0__ to __enable_uart=1__
* Pi users: Now you can power down your Pi.
* Connect the module to the Raspberry Pi or to your USB serial to TTL converter (it MUST be a 3.3V level converter!)
  * For modules without a KEY pin (button instead): Connect +5v, ground, TX and RX correctly.
  * For modules with a KEY pin: Connect +5v, ground, TX, RX and then connect the KEY pin to the +3.3V rail on the Pi (NOT 5V).
* If your module has a button instead of a KEY pin - hold down this button and connect power to the Raspberry Pi or USB TTL adaptor. Let go after about 2 seconds.
* If your module has a KEY pin, just power up the Pi or USB TTL adaptor.
* Run this program without any parameters for instructions. You will need to use it twice, once for each module.

## Example: Configuring a slave device (do this first before configuring the master)

```
zipplet@buildpi1:~/build/hc05config $ ./hc05config /dev/ttyAMA0 info
Opening the serial device... OK
Checking if the module is responding... OK
Firmware version                              : 2.0-20100601
Device state                                  : INITIALIZED
Bluetooth address                             : 1234:12:abcdef
Password / passcode / PIN                     : 1234
UART (baud rate, extra stop bits, parity bit) : 38400,0,0
Master / slave mode (SPP)                     : SLAVE
Connection mode (CMODE)                       : 0
Number of authenticated devices               : 0
Most recent bluetooth remote peer address     : 0:0:0
Configured bind address (if master)           : 0:0:0
zipplet@buildpi1:~/build/hc05config $ ./hc05config /dev/ttyAMA0 setslave 3333
Opening the serial device... OK
Checking if the module is responding... OK
Configuring the module as a slave device with the PIN code 3333
Confirming the configuration...
Complete.
Bluetooth device address to use to pair with the master: 1234:12:abcdef
zipplet@buildpi1:~/build/hc05config $ ./hc05config /dev/ttyAMA0 setdatabaudrate 115200
Opening the serial device... OK
Checking if the module is responding... OK
Changing the baud rate to 115200 with 1 stop bit and no parity
Confirming the configuration...
Complete.

# This next step is optional if you will be disconnecting the device, etc. It takes it out of config mode.
zipplet@buildpi1:~/build/hc05config $ ./hc05config /dev/ttyAMA0 reboot
Opening the serial device... OK
Checking if the module is responding... OK
Rebooting/resetting the module (this will not have the intended effect if the module has a KEY pin).
Complete. The module should now be in data mode.
```

## Example: Configuring a master device to pair to the slave configured above

```
# This reset command step is not really needed, just demonstrating it
zipplet@buildpi1:~/build/hc05config $ ./hc05config /dev/ttyAMA0 reset
Opening the serial device... OK
Checking if the module is responding... OK
Resetting module to factory default settings
Clearing any paired devices
Complete.
zipplet@buildpi1:~/build/hc05config $ ./hc05config /dev/ttyAMA0 info
Opening the serial device... OK
Checking if the module is responding... OK
Firmware version                              : 2.0-20100601
Device state                                  : INITIALIZED
Bluetooth address                             : 9999:11:555555
Password / passcode / PIN                     : 1234
UART (baud rate, extra stop bits, parity bit) : 38400,0,0
Master / slave mode (SPP)                     : SLAVE
Connection mode (CMODE)                       : 0
Number of authenticated devices               : 0
Most recent bluetooth remote peer address     : 0:0:0
Configured bind address (if master)           : 0:0:0
zipplet@buildpi1:~/build/hc05config $ ./hc05config /dev/ttyAMA0 setmaster 3333 1234:12:abcdef
Opening the serial device... OK
Checking if the module is responding... OK
Configuring the module as a master device with the PIN code 3333 pairing to device 1234:12:abcdef
Confirming the configuration...
Complete.
zipplet@buildpi1:~/build/hc05config $ ./hc05config /dev/ttyAMA0 setdatabaudrate 115200
Opening the serial device... OK
Checking if the module is responding... OK
Changing the baud rate to 115200 with 1 stop bit and no parity
Confirming the configuration...
Complete.

# This next step is optional if you will be disconnecting the device, etc. It takes it out of config mode.
zipplet@buildpi1:~/build/hc05config $ ./hc05config /dev/ttyAMA0 reboot
Opening the serial device... OK
Checking if the module is responding... OK
Rebooting/resetting the module (this will not have the intended effect if the module has a KEY pin).
Complete. The module should now be in data mode.
```

## Example: Loopback testing

Now both modules are configured, leave one of them plugged into the Raspberry Pi (issue a "reboot" command from hc05config if you have not). Plug the other into a breadboard, short TX and RX together with a jumper wire, and apply power. The LEDs on both modules should settle down into a regular pulse pattern. Make sure you use the baud rate you configured using __setdatabaudrate__ - if you did not use that command, the baud rate will be __9600__.

```
zipplet@buildpi1:~/build/hc05config $ ./hc05config /dev/ttyAMA0 loopbacktest 115200
Opening the serial device... OK
Starting an endless loopback test.
The current date and time will be sent, and the program will wait for a response and display it.
Press ctrl+c to stop.
------------------------------------
Received: 3-1-17 02:19:08
Received: 3-1-17 02:19:09
Received: 3-1-17 02:19:10
Received: 3-1-17 02:19:12
^C
```

Now that both modules are configured, you can do what you want with them - when power cycled they will always re-establish the connection. Use them both with microcontrollers? Connect both of them to USB<->TTL converters and make a wireless serial connection between 2 computers? Endless possibilities!
