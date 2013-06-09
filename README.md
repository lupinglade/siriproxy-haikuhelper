# siriproxy-haikuhelper

Integrates HaikuHelper with Siri-Proxy. This allows you to control your HAI smarthome via Siri.

## Requirements

* [HaikuHelper 2.90 or later](http://www.haikuautomation.com/products/haikuhelper) (running on a machine that is always on)
* [httparty](http://github.com/jnunemaker/httparty) (gem dependency, auto-installed)
* [SiriProxy](http://github.com/plamoni/SiriProxy)

Note: the Install guide below covers installation of everything but HaikuHelper.

## Install

Add this configuration entry to your ~/.siriproxy/config.yml:

```
    - name: 'HaikuHelper'
      git: 'git://github.com/lupinglade/siriproxy-haikuhelper.git'
      url: 'http://localhost:9399'
      controller_name: 'My Home'
      password: 'secret'
```

Don't forget to set the url/controller_name and password correctly.

Then run siriproxy bundle (this will load the plugin from this git repository and install the httparty gem if needed)

## Guide

Here are the basic steps needed to get voice control of your HAI controller via HaikuHelper and SiriProxy:

These steps/commands are to be run on the machine that will be running HaikuHelper/SiriProxy (ie. your HaikuHelper server) under an admin user (not root).

* Install Apple Xcode from the Mac App Store (free download).

* Launch Xcode and go to the Preferences window, click "Downloads" and install the Command Line Tools package.

* Open up a Terminal window and install RVM (the Ruby Version Manager):

```
\curl -#L https://get.rvm.io | bash -s stable --autolibs=3
```

* Close and re-open the Terminal window to reload the RVM environment.

* Run the following command to install Ruby 2.0.0-p0 using RVM:

```
rvm install 2.0.0-p0 --autolibs=3
```

* Now install the siriproxy gem:

```
gem install siriproxy
```

* Create the ~/.siriproxy configuration directory (in your home):

```
mkdir ~/.siriproxy
```

* Copy over the example configuration file to your siriproxy configuration directory:

```
cp ~/.rvm/gems/ruby-2.0.0-p0/gems/siriproxy-0.5.4/config.example.yml ~/.siriproxy/config.yml
```

* Edit the ~/.siriproxy/config.yml file using a text/code editor and add this entry to the plugin section with the proper values:

```
    - name: 'HaikuHelper'
      git: 'git://github.com/lupinglade/siriproxy-haikuhelper.git'
      url: 'http://localhost:9399'
      controller_name: 'My Home'
      password: 'secret'
```

* Tip: Be careful to use exact spacing in the config.yml file as the YML format is indentation-sensitive.

* You can also update the config.yml file to set server_ip to the LAN IP of the machine that will be running SiriProxy and the user, which means you won't need to pass them later when you start siriproxy.

* Run the siriproxy command to bundle the siriproxy-haikuhelper plugin:

```
siriproxy bundle
```

* Generate the certificates for siriproxy:

```
siriproxy gencerts
```

* Transfer the generated certificate (ca.pem) to your phone (you can just e-mail it to yourself):

```
open ~/.siriproxy/
```

* On you your iOS devices, open the e-mail and tap the ca.pem and accept it to add it to your certificate chain.

* Start SiriProxy (replace XXX.XXX.XXX.XXX with the LAN IP of the machine running SiriProxy/HaikuHelper):

```
rvmsudo siriproxy server -d XXX.XXX.XXX.XXX -u nobody
```

If you get an error about port 443 or 53 being in use, make sure your machine is not running a web server or DNS server. On OS X Mountain Lion (and Lion) Server you will need to unload the httpd service:

```
sudo launchctl unload -w /System/Library/LaunchDaemons/org.apache.httpd.plist
```

* Tell your phone to use your SiriProxy server's IP as its DNS server (under Settings > Wi-Fi > Your network)

* Test the server by telling Siri "helper status" or "system status"

Note: You can update siriproxy and siriproxy-haikuhelper in the future by running:

```
siriproxy update
```

Note: Further information on installing SiriProxy is available on the project's github page. 

## Vocabulary

Then, once you have it working, here are some of the commands, many can be prefixed/suffixed as you wish. The format of this section is:

```
required
{required} or {required|choose|one|of}
(optional) or (optional|choose|one|of)
```

### Control commands:

* Disarm (all areas)
* Disarm (the) {area_name}
* Arm (all areas) (in) {day|night|away|vacation|day instant|night delayed} (mode)
* Arm (the) {area_name} (in) {day|night|away|vacation|day instant|night delayed} (mode)
* {Lock|Unlock} all (the|of the) {locks|readers|access control readers}
* {Lock|Unlock} (the) {reader_name}
* {Bypass|Restore} (the) {zone_name}
* (Run) (the) {button_name} {button|macro}
* {Turn on|Turn off|Mute|Unmute} all audio (zones)
* {Turn on|Turn off|Mute|Unmute|Rewind|Previous|Repeat|Skip|Forward|Next|Play|Pause|Unpause} (the) {audio|music|song|track} in (the) {audio_zone_name}
* {Set|Change} (the) {audio_zone_name} source to (the) {audio_source_name}
* {Set|Change} (the) {audio_zone_name} volume to {0-100} (percent)
* {Set|Change} (the) {thermostat_name} {heat setpoint|cool setpoint|humidify setpoint|dehumidify setpoint} to (negative) {0.0-100.0} (degrees|percent)
* {Set|Change} (the) {thermostat_name} fan setting to {automatic|auto|always on|on|cycle}
* {Set|Change} (the) {thermostat_name} hold setting to {on|off}
* {Set|Change} (the) {sensor_name} {high setpoint|low setpoint} to (negative) {0.0-100.0} (degrees|percent)
* (Turn) all lights {on|off}
* {Turn on|Turn off|Brighten|Dim} (the) {light_name} (in (the) {room_name}) (for {1-60} {seconds|minutes|hours})
* {Set|Change} (the) {light_name} (level) (in (the) {room_name}) to {0-100} (percent)
* {Set|Change} (the) {room_name} scene to {a|b|c|d|one|two|three|four}

### Query commands:

* What is the energy cost?
* What is (the) {area_name} area {status|mode}?
* What is (the) {zone_name} zone status?
* What is the outdoor temperature?
* What is the outdoor humidity?
* What is the {temperature|humidity|heat setpoint|cool setpoint|humidify setpoint|dehumidify setpoint|mode|fan setting} {in|on|at|for} (the) {thermostat_name}?
* What is the {value|high setpoint|low setpoint} for (the) {sensor_name}?
* What time is (the) {sunrise|sunset} (time)?

### System commands:

* System status
* System notices
* System messages
* Helper status
* Helper send notification
* Helper reload

The last one reloads the object names from the HaikuHelper API, which is useful if you've renamed some objects or added new ones.

### Examples:

* Disarm all areas
* Arm the garage in away mode
* Bypass the front door
* Skip the song in the great room
* Mute the audio in the basement
* Change the great room source to the radio
* Change the basement heat setpoint to 21 degrees
* Change the loft fan setting to automatic
* Turn off the chandelier in the living room
* Turn on the fireplace pot lights
* Dim the chandelier in the foyer
* Change the fireplace pot lights level to 50 percent
* Turn all lights off
* What is the outdoor humidity?
* What is the front door zone status?
* What is the temperature on the main level?
* What is the sunset time?

Note: this plugin will match by best available description for an object, ie. it will first try to match a "description" as set in HaikuHelper (via Window -> Object Editor), if not available it will try to match the name set on the controller. Hence, you can tweak the names of objects in HaikuHelper's Object Editor to make it easier to control your system via Siri.

Note 2: the vocabulary will be expanding and changing as the project matures.

## License

MIT

## Links

* https://github.com/plamoni/SiriProxy
* http://cocoontech.com/forums/forum/67-haiku-haikuhelper/
* http://www.haikuautomation.com/
* http://www.nullriver.com/

## Contributing

* Fork the project.
* Make your feature addition or bug fix.
* Send me a pull request.
