#Atmel Xplained Nano (ATTiny104) USART experiment

Control pins PA0-PA7 via USART using a single byte using Great Cow BASIC.

Great Cow BASIC generated real ATMEL ASM and the C code maks the complexities of the ATTiny104.

Full credit to modalpdx, see https://github.com/modalpdx/Tiny104_USART

##BUILDING BLOCKS:

Written for an [Atmel Xplained Nano ATTiny104 eval board](http://www.atmel.com/tools/ATTINY104-XNANO.aspx).
This board includes a TPI programmer (no debugger), USB connectivity, one
button, and one LED. It also has 1k of flash and 32 bytes of RAM, which is
tight. All communication happens through the single USART built into the
ATTiny104 MCU. The pins for this USART are also routed through the USB
connector so connecting via a micro USB cable works fine (no jumper wires
or USB/TTL devices are required).

If you are not using this board, you will need to adjust ports, pins, etc.

##CONTROLLING THE BOARD:

Because of the TPI programmer that is required for programming ATTiny104
MCUs to use Atmel Studio on Windows or just to program use the ATPROG [here](https://github.com/Anobium/Tiny104_USART/blob/master/ATPrpogrammer/ATPrpogrammer.zip)
 to program this MCU. On Windows, I recommend you use Terminal as
your terminal program. It offers significantly more granular functionality
than basic serial terminals.

Terminal can "Send" tab can send bytes (enter the decimal form in the --Transmit --
form field and click "Send").  If you're not on Windows, find a
terminal program that allows sending bytes.

The output pins used here are PA0 - PA7, mapped to bits 0 - 7 in the byte
you'll be sending to the MCU. 5V logic is used here, so don't plug in 3.3V
components without adding some kind of voltage regulation.

Setting a bit for a pin in a serial terminal and then sending the
resulting byte to the board will turn on the pin (and its attached
component) only.  Unset the bit and send the resulting byte to turn it
off.

To set ON the LED send #032.  Which is setting bit 4.
To set OFF the LED send #000.  Which is clearing bit 4.

NOTE: The on/off status of ALL COMPONENTS must be sent in each byte.
State is not saved between received bytes! Whatever is in the byte that is
received will determine what is on and what is off.

So, in "Send" tab (or whatever serial terminal you're using):

- Sending #003  (00000011) will turn on pins PA0 and PA1 and turn the rest off.
- Sending 0x066 (01000010) will turn on pins PA6 and PA1 and turn the rest off.
- Sending 0x255 (11111111) will turn on all pins.
- Sending 0x000 (00000000) will turn off all pins.

You get the idea.

##MISC:

This program uses interrupts instead of polling. It's better that way.

Due to the proprietary nature of TPI programming and mEDBG programmers
(both of which are required for programming ATTiny104 MCUs), you will need
Atmel Studio on Windows, or the Partial installation see [here](https://github.com/Anobium/Tiny104_USART/blob/master/ATPrpogrammer/ATPrpogrammer.zip)  to program
the board.

The serial port in the terminal program needs to be set to 9800/8N1 to
communicate.

I admit that shoving an entire byte into PORTA is not very glamorous.
I'm trying to keep things really small which means no arrays, no enums,
no loops or switch statements, etc. This is a dumb device, and like many
dumb devices, it trusts you completely. Sending a byte and processing it
immediately (and then forgetting about it) makes this all very compact.
On my system, Great Cow BASIC reports 190 PROGMEM bytes of storage and 3 bytes of
RAM used, which fall well within the device's 1k of storage and 32
bytes of memory.  Considering that this implementation that supports up to 115k, the 
value sent is returned to the terminal, and you can select any OSC internal operating frequency 
... not too bad.

##CAVEATS:

I have tested this using LEDs and a solid state relay and it has worked
flawlessly.

You may have to adjust the OSCCAL as the internal oscillator is not very good.
- For 9600 BPS use OSCCAL = OSCCAL - 5
- For 115200 BPS use OSCCAL = OSCCAL - 22
