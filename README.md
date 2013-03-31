<<<<<<< HEAD
# siriproxy-haikuhelper

Integrates HaikuHelper with Siri-Proxy

## Install

```
gem install siriproxy-haikuhelper
```

## Requirements

* httparty
* siriproxy

## Guide

We assume you have already configured Siri-Proxy as per the project's documentation. Hint: Install it on the same machine as the one running HaikuHelper, use OS X Server DNS service to spoof the guzzoni.apple.com server and set the IP for DNS on your iOS devices to point to your HaikuHelper machine's IP.

You will need to copy over the configuration lines from the sample-config.yml file into your siriproxy config.yml file and enter valid values.

Then, once you have it working, here are some of the commands, many can be prefixed/suffixed as you wish:

* Disarm|Arm day instant|Arm night delayed|Arm day|Arm night|Arm away|Arm vacation (the) area_name
* Lock|Unlock (the) reader_name
* Audio on|off|mute|unmute in (the) audio_zone_name
* Bypass|Restore (the) zone_name
* Macro button_name
* (Turn) all lights on|off
* Turn on|off (the) light_name in (the) room_name
* Turn on|off (the) light_name
* (What is the) outdoor temperature?
* (What is the) outdoor humidity?
* Helper status
* Helper reload

The last one reloads the object names from the HaikuHelper API, which is useful if you've renamed some objects or added new ones.

Note: this plugin will use the best available description for an object, ie. it will first try to use a "description" as set in HaikuHelper (via Window -> Object Editor), if not available it will try to use the name set on the controller.

## Help and Docs

* https://github.com/plamoni/SiriProxy
* http://www.haikuautomation.com/

## Contributing

* Fork the project.
* Make your feature addition or bug fix.
* Send me a pull request.
=======
siriproxy-haikuhelper
=====================

Siri-Proxy HaikuHelper home automation plugin.
>>>>>>> 0d141be3ea3418b361453ea909f3576a041d310a
