# siriproxy-haikuhelper

Integrates HaikuHelper with Siri-Proxy

## Requirements

* HaikuHelper 2.90 or later (running on a machine that is always on)
* httparty (gem dependency, auto-installed)
* siriproxy

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

* Install Apple Xcode from the Mac App Store (free download).

* Launch Xcode and go to the Preferences window, click "Downloads" and install the Command Line Tools package.

These commands are to be run on the machine that will be running HaikuHelper/SiriProxy (ie. your HaikuHelper server).

* Open up a Terminal window and install RVM (the Ruby Version Manager):

```
\curl -#L https://get.rvm.io | bash -s stable --autolibs=3
```

* Close and re-open the Terminal window to reload the RVM environment.

* Run the following command to install Ruby 2.0.0-p0 using RVM.

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
cp ~/.rvm/gems/ruby-2.0.0-p0/gems/siriproxy-0.5.2/config.example.yml ~/.siriproxy/config.yml
```

* Edit the ~/.siriproxy/config.yml file using a text/code editor and add this entry to the plugin section with the proper values:

```
    - name: 'HaikuHelper'
      git: 'git://github.com/lupinglade/siriproxy-haikuhelper.git'
      url: 'http://localhost:9399'
      controller_name: 'My Home'
      password: 'secret'
```

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

* Test the server by telling Siri "helper status"

Note: You can update siriproxy and siriproxy-haikuhelper in the future by running:

```
siriproxy update
```

Note: Further information on installing SiriProxy is available on the project's github page. 

## Vocabulary

Then, once you have it working, here are some of the commands, many can be prefixed/suffixed as you wish. The format of this section is:

```
required
{choose|one|of}
(optional)
```

Control commands:

* {Disarm|Arm day instant|Arm night delayed|Arm day|Arm night|Arm away|Arm vacation} (the) {area_name}
* {Lock|Unlock} all (the|of the) {locks|readers|access control readers}
* {Lock|Unlock} (the) {reader_name}
* {Bypass|Restore} (the) {zone_name}
* {Macro|Button} {button_name}
* All {music|audio|speakers|audio zones} {on|off|mute|unmute}
* {Audio|Music|Speakers|Audio zone} {on|off|mute|unmute} in (the) {audio_zone_name}
* Set the (the) {thermostat_name} {heat setpoint|cool setpoint|humidify setpoint|dehumidify setpoint} to (negative) {0.0-100.0} (degrees|percent)
* Set the (the) {thermostat_name} fan setting to {automatic|auto|always on|on|cycle}
* Set the (the) {sensor_name} {high setpoint|low setpoint} to (negative) {0.0-100.0} (degrees|percent)
* (Turn) all lights {on|off}
* {Turn on|Turn off|Brighten|Dim} (the) {light_name} (in (the) {room_name})
* Set (the) {light_name} (in (the) {room_name}) to {0-100} (percent)
* Set scene {a|b|c|d} in (the) {room_name}

Query commands:

* What is the energy cost?
* What is the {area_name} area {status|mode}?
* What is the {zone_name} zone status?
* What is the outdoor temperature?
* What is the outdoor humidity?
* What is the {temperature|humidity|heat setpoint|cool setpoint|humidify setpoint|dehumidify setpoint|mode|fan setting} {in|on|at|for} (the) {thermostat_name}?
* What is the {value|high setpoint|low setpoint} for (the) {sensor_name}?

System commands:

* System status
* System notices
* Helper reload

The last one reloads the object names from the HaikuHelper API, which is useful if you've renamed some objects or added new ones.

Note: this plugin will match the best available description for an object, ie. it will first try to use a "description" as set in HaikuHelper (via Window -> Object Editor), if not available it will try to use the name set on the controller.

Note 2: security code validation is not yet working.

Note 3: the vocabulary will be expanding and changing as the project matures.

## Links

* https://github.com/plamoni/SiriProxy
* http://www.haikuautomation.com/
* http://www.nullriver.com/

## Contributing

* Fork the project.
* Make your feature addition or bug fix.
* Send me a pull request.
