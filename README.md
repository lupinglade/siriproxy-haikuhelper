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
      #path: './plugins/siriproxy-haikuhelper'
      url: 'http://localhost:9399'
      controller_name: 'My Home'
      password: 'secret'
```

Don't forget to set the url/controller_name and password correctly.

Then run siriproxy bundle (this will load the plugin from this git repository and install the httparty gem if needed)

## Guide

Here are the basic steps needed to get voice control of your HAI controller via HaikuHelper and SiriProxy:

1. Install Apple Xcode from the Mac App Store (free download).

2. Launch Xcode and go to the Preferences window, click "Downloads" and install the Command Line Tools package.

These commands are to be run on the machine that will be running HaikuHelper/SiriProxy (ie. your HaikuHelper server).

3. Open up a Terminal window and install RVM (the Ruby Version Manager):

```
\curl -#L https://get.rvm.io | bash -s stable --autolibs=3
```

4. Close and re-open the Terminal window to reload the RVM environment.

5. Run the following command to install Ruby 2.0.0-p0 using RVM.

```
rvm install 2.0.0-p0 --autolibs=3

```

6. Now install the siriproxy gem:

```
gem install siriproxy
```

7. Create the ~/.siriproxy configuration directory (in your home):

```
mkdir ~/.siriproxy
```

8. Copy over the example configuration file to your siriproxy configuration directory:

```
cp ~/.rvm/gems/ruby-2.0.0-p0/gems/siriproxy-0.5.2/config.example.yml ~/.siriproxy/config.yml
```

9. Edit the ~/.siriproxy/config.yml file using a text/code editor and add this entry to the plugin section with the proper values:

```
    - name: 'HaikuHelper'
      git: 'git://github.com/lupinglade/siriproxy-haikuhelper.git'
      #path: './plugins/siriproxy-haikuhelper'
      url: 'http://localhost:9399'
      controller_name: 'My Home'
      password: 'secret'
```

10. You can also update the config.yml file to set server_ip to the LAN IP of the machine that will be running SiriProxy and the user, which means you won't need to pass them later when you start siriproxy.

11. Run the siriproxy command to bundle the siriproxy-haikuhelper plugin:

```
siriproxy bundle
```

12. Generate the certificates for siriproxy:

```
siriproxy gencerts
```

13. Transfer the generated certificate (ca.pem) to your phone (you can just e-mail it to yourself):

```
open ~/.siriproxy/
```

14. On you your iOS devices, open the e-mail and tap the ca.pem and accept it to add it to your certificate chain.

15. Start SiriProxy (replace XXX.XXX.XXX.XXX with the LAN IP of the machine running SiriProxy/HaikuHelper):

```
rvmsudo siriproxy server -d XXX.XXX.XXX.XXX -u nobody
```

16. Tell your phone to use your SiriProxy server's IP as its DNS server (under Settings > Wi-Fi > Your network)

17. Test the server by telling Siri "helper status"

Note: You can update siriproxy and siriproxy-haikuhelper in the future by running:

```
siriproxy update
```

Note: Further information on installing SiriProxy is available on the project's github page. 

## Vocabulary

Then, once you have it working, here are some of the commands, many can be prefixed/suffixed as you wish:

* Disarm|Arm day instant|Arm night delayed|Arm day|Arm night|Arm away|Arm vacation (the) area_name
* Lock|Unlock (the) reader_name
* Audio on|off|mute|unmute in (the) audio_zone_name
* Bypass|Restore (the) zone_name
* Macro button_name
* (Turn) all lights on|off
* Turn on|off (the) light_name in (the) room_name
* Turn on|off (the) light_name
* What is the outdoor temperature?
* What is the outdoor humidity?
* Helper status
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
