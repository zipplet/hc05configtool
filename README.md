# hc05configtool
A tool for configuring HC-05 wireless modules easily.

## Eh? What's this?
There is a common wireless module used by hobbyists when building things that need wireless communication locally between each other called the "HC-05" (there is also a variant called the "HC-06" but I do not have any).

Once they are configured they are nice - power up both modules and they immediately establish a virtual serial link at TTL voltage levels. Temporarily power cycle one and it will reconnect. You can even have multiple projects using these modules in the same room, and they will connect to the correct modules acting like virtual serial cables. Small amounts of packet loss are tolerated by the module and data gets retransmitted automatically - very nice.

They are perfect for things like microcontrollers / Arduino / Raspberry Pi. They use bluetooth, but hide all of that from you. They tend to come pre-soldered onto a breakout board that just exposes TX, RX, power, ground, sometimes a "KEY" pin (if not a button instead) and often a couple of other pins for you to determine if they have established a link or not. 

The problem is they come unconfigured. Configuring them is an absolute pain. You have to put them into programming mode, then send a specific sequence of commands to both modules before they will pair with each other. Get it wrong and you can make it very insecure or just end up banging your head against the desk in frustration.

## How do I use it?
__At the moment, only Linux (Raspberry Pi) is supported; Windows support will come later__

All you need to do is:
* Get a pair of modules (and for now, a Raspberry Pi - later I will support Windows and Linux on a PC with a TTL USB cable, and perhaps even Arduino as a virtual TTL USB cable or via a sketch that you upload and run)
* Disable the serial console on your Raspberry Pi (sudo raspi-config) and then turn off the Raspberry Pi.
* Connect the module to the Raspberry Pi:
  * For modules without a KEY pin (button instead): Connect +5v, ground, TX and RX correctly.
  * For modules with a KEY pin: Connect +5v, ground, TX, RX and then connect the KEY pin to the +3.3V rail on the Pi (NOT 5V).
* Run this program without any parameters for instructions. You will need to use it twice, once for each module.
