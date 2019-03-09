
# NodeMCU 433Mhz UDP gateway

The [NodeMCU](https://www.nodemcu.com/index_en.html) project is firmware that allows anyone to write
very simple, yet powerful lua scripts to do simple embedded things on ESP8266 based modules.

They also have [NodeMCU development kits](https://www.nodemcu.com/index_en.html#fr_54747661d775ef1a3600009e)
which I really enjoy using when doing simple hardware hacks.

This project is about a lua script for such a device when used in combination with a [433 Mhz transmitter](https://www.google.com/search?q=433mhz+transmitter).
Most transmissions on 433 Mhz are [OOK](https://en.wikipedia.org/wiki/On-off_keying) encoded.
With this script you can generate the actual data to be send on any "big" machine, submit the
delay sequence via UDP and leave only the final data transmission to the ESP8266 module.

## Hardware Setup

This is really easy. The 433Mhz transmitter only has 3 pins: GND, VIN, DATA. Connect them like this:

 NodeMCU | 433Mhz Transmitter
:-------:|:------------------:
   GND   | GND
   VIN   | VIN
   D6    | DATA

## Software Setup

1) First you need to have a working NodeMCU setup. For that, build yourself a [custom NodeMCU firmware](https://nodemcu-build.com).
2) Upload that firmware to the device (using [esptool.py](https://github.com/espressif/esptool) for example)
3) Modify init.lua to include your wifi SSID and password
4) Upload init.lua to the NodeMCU device (I use [ESPlorer](https://esp8266.ru/esplorer/) for that usually)

Your gateway should be ready to go! The IP should be visible on the serial line. If you send packets such as

```
  400 800 400 400 400
```

to UDP port 1236 on that device, it will emit high for 400 us, low for 800 us, high for 400 us, low for 400 us, high for 400 us, then switch to low.
