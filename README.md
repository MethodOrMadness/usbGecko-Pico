# usbGecko-Pico
a USB Gecko clone... for the pi pico

# Why?
Well, the CPLD in the gecko isnt easy to come by, ask me how i know, so im going to attempt to rewrite the Verilog to C code and use it on the pico

# What needs to be done?
Currently, everything
* Translate the Verliog to C
* Adapt the Translated code to run on the pico
* Debug / Test
* Create a writeup / documentation on how to build one

# What can you do to help?
Well, if you know Verilog, that is the main obstacle now

If you have any PCB Design experience, that could also come in handy for when we get a prototype working

If you have any ideas to contribute, open an issue or PR with any information

# Points of failure
After some more research, it seems that a pico *could* be too slow to perform this task, but a faster microcontroller(like a [teensy 4.0][2], clocking in at 600mhz)

# Credits
Streetwalker on [GC-Forever][1] for the OG USB Gecko Clone

[1]: https://www.gc-forever.com/forums/viewtopic.php?f=26&t=3089
[2]: https://www.electronics-lab.com/new-teensy-4-0-fastest-dev-board-powered-arm-cortex-m7/
