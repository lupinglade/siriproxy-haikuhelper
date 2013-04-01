require 'cora'
require 'siri_objects'
require 'pp'
require 'haikuhelper'


class SiriProxy::Plugin::HaikuHelper < SiriProxy::Plugin
  def initialize(config)
    if config["url"].nil?
      puts "siriproxy-haikuhelper: Missing configuration, please define url, controller_name and password in your config.yml file." 
    else
      @helper = HaikuHelperAPI.new config["url"], config["controller_name"], config["password"]
      reload_configuration
    end
  end

  #HH API shorthand
  def api(cmd)
    @helper.api cmd
  end

  #Reloads configuration from HH server
  def reload_configuration
    puts "Reloading controller configuration..."

    @readers = api "controller.accessControlReaders"
    @areas = api "controller.areas"
    @audio_zones = api "controller.audioZones"
    @auxiliary_sensors = api "controller.auxiliarySensors"
    @buttons = api "controller.buttons"
    @thermostats = api "controller.thermostats"
    @units = api "controller.units"
    @zones = api "controller.zones"
  end

  #Finding methods

  #Find an object by name inside objects
  def find_object_by_name(objects, name)
    objects.detect { |o| o["bestDescription"].casecmp(name) == 0 }
  end

 #Find a light unit by name
  def find_light_unit(name, room_name = nil)
    @units.detect { |l| l["bestDescription"].casecmp(name) == 0 && (room_name == nil || l["roomDescription"] =~ /#{Regexp.escape(room_name)}/i) }
  end

 #Find a room unit by name
  def find_room_unit(room_name)
    @units.detect { |l| l["isRoom"] && l["bestDescription"].casecmp(name) == 0 }
  end

  #Control commands

  #{Disarm|Arm day instant|Arm night delayed|Arm day|Arm night|Arm away|Arm vacation} (the) {area_name}
  listen_for /(disarm|arm day instant|arm night delayed|arm day|arm night|arm away|arm vacation)(?: the)? (.*)/i do |mode,area_name|
    area_name.strip!
    area = find_object_by_name @areas, area_name
  
    if area.nil?
      say "I couldn't find an area named #{area_name}!"
    else
      response = ask "Please say your security code to #{mode} #{area_name}:"

      if(response.downcase != "cancel")
        oid = area["oid"]

        case mode.downcase
          when "disarm"
            api "helper.objectWithOID('#{oid}').setMode(0)"
            say "Okay, the #{area_name} has been disarmed!"
          when "arm day"
            api "helper.objectWithOID('#{oid}').setMode(1)"
            say "Arming the #{area_name} in mode day..."
          when "arm night"
            api "helper.objectWithOID('#{oid}').setMode(2)"
            say "Arming the #{area_name} in mode night..."
          when "arm away"
            api "helper.objectWithOID('#{oid}').setMode(3)"
            say "Arming the #{area_name} in mode away..."
          when "arm vacation"
            api "helper.objectWithOID('#{oid}').setMode(4)"
            say "Arming the #{area_name} in mode vacation..."
          when "arm day instant"
            api "helper.objectWithOID('#{oid}').setMode(5)"
            say "Arming the #{area_name} in mode day instant..."
          when "arm night delayed"
            api "helper.objectWithOID('#{oid}').setMode(6)"
            say "Arming the #{area_name} in mode night delayed..."
        end
      else
        say "Sorry, your security code could not be validated."
      end
    end

    request_completed
  end

  #{Lock|Unlock} (the) {reader_name}
  listen_for /(unlock|lock)(?: the)? (.*)/i do |action,reader_name|
    reader_name.strip!
    reader = find_object_by_name @readers, reader_name
  
    if reader.nil?
      say "I couldn't find an access control named #{reader_name}!"
    else
      response = ask "Please say your security code to #{action} #{reader_name}:"

      if(response.downcase != "cancel")
        oid = reader["oid"]

        case action.downcase
          when "unlock"
            api "helper.objectWithOID('#{oid}').unlock()"
            say "Okay, #{reader_name} has been unlocked."
          when "lock"
            api "helper.objectWithOID('#{oid}').lock()"
            say "Okay, #{reader_name} has been lock."
        end
      else
        say "Sorry, your security code could not be validated."
      end
    end

    request_completed
  end

  #{Audio|Music|Speakers} {on|off|mute|unmute} in (the) {audio_zone_name}
  listen_for /(?:audio|music|speakers) (on|off|mute|unmute) in(?: the)? (.*)/i do |action,audio_zone_name|
    audio_zone_name.strip!
    audio_zone = find_object_by_name @audio_zones, audio_zone_name
  
    if audio_zone.nil?
      say "I couldn't find an audio zone named #{audio_zone_name}!"
    else
      oid = audio_zone["oid"]

      case action.downcase
        when "on"
          api "helper.objectWithOID('#{oid}').on()"
          say "Okay, #{audio_zone_name} audio has been turned on."
        when "off"
          api "helper.objectWithOID('#{oid}').off()"
          say "Okay, #{audio_zone_name} audio has been turned off."
        when "mute"
          api "helper.objectWithOID('#{oid}').mute()"
          say "Okay, #{audio_zone_name} audio has been muted."
        when "unmute"
          api "helper.objectWithOID('#{oid}').unmute()"
          say "Okay, #{audio_zone_name} audio has been unmuted."
      end
    end

    request_completed
  end

  #{Bypass|Restore} (the) {zone_name}
  listen_for /(bypass|restore)(?: the)? (.*)/i do |action,zone_name|
    zone_name.strip!
    zone = find_object_by_name @zones, zone_name
  
    if zone.nil?
      say "I couldn't find a zone named #{zone_name}!"
    else
      response = ask "Please say your security code to #{action} #{zone_name}:"

      if(response.downcase != "cancel")
        oid = zone["oid"]

        case action.downcase
          when "bypass"
            api "helper.objectWithOID('#{oid}').bypass()"
            say "Okay, #{zone_name} has been bypassed."
          when "restore"
            api "helper.objectWithOID('#{oid}').restore()"
            say "Okay, #{zone_name} has been restored."
        end
      else
        say "Sorry, your security code could not be validated."
      end
    end

    request_completed
  end

  #Macro {button_name}
  listen_for /macro (.*)/i do |button_name|
    button_name.strip!
    button = find_object_by_name @buttons, button_name
  
    if button.nil?
      say "I couldn't find a button named #{button_name}!"
    else
      response = ask "Are you sure you want to activate button #{button_name}?"

      if(response =~ CONFIRM_REGEX)
        oid = button["oid"]
        api "helper.objectWithOID('#{oid}').activate()"
        say "Okay, button #{button_name} activated."
      else
        say "Alright, I won't activate it."
      end
    end

    request_completed
  end

  #All lights {on|off}
  listen_for /all lights (on|off)/i do |action|
    response = ask "Are you sure you want to turn #{action} all of the lights?"

    if(response =~ CONFIRM_REGEX)
      if action == "on"
        api "controller.sendAllLightsOnCommand()"
      else
        api "controller.sendAllLightsOffCommand()"
      end
        say "Turning #{action} all of the lights."
    else
      say "Alright, cancelled."
    end

    request_completed
  end

  #{Turn on|Turn off|Brighten|Dim} (the) {light_name} in (the) {room_name}
  listen_for /(turn on|turn off|brighten|dim)(?: the)? (.*) in(?: the)? (.*)/i do |action, light_name, room_name|
    room_name.strip!
    unit = find_light_unit light_name, room_name
  
    if unit.nil?
      if room_name.nil?
        say "I couldn't find a unit named #{light_name}!"
      else
        say "I couldn't find a unit named #{light_name} in the #{room_name}!"
      end
    else
      oid = unit["oid"]

      case action.downcase
        when "turn on"
          api "helper.objectWithOID('#{oid}').on()"
          say "Okay, unit #{light_name} turned on."
        when "turn off"
          api "helper.objectWithOID('#{oid}').off()"
          say "Okay, unit #{light_name} turned off."
        when "brighten"
          api "helper.objectWithOID('#{oid}').brighten(3)"
          say "Okay, unit #{light_name} brightened."
        when "dim"
          api "helper.objectWithOID('#{oid}').dim(3)"
          say "Okay, unit #{light_name} dimmed."
      end
    end

    request_completed
  end

  #{Turn on|Turn off|Brighten|Dim} (the) {light_name}
  listen_for /(turn on|turn off|brighten|dim)(?: the)? (.*)/i do |action, light_name|
    light_name.strip!
    unit = find_light_unit light_name
  
    if unit.nil?
      say "I couldn't find a unit named #{light_name}!"
    else
      oid = unit["oid"]

      case action.downcase
        when "turn on"
          api "helper.objectWithOID('#{oid}').on()"
          say "Okay, unit #{light_name} turned on."
        when "turn off"
          api "helper.objectWithOID('#{oid}').off()"
          say "Okay, unit #{light_name} turned off."
        when "brighten"
          api "helper.objectWithOID('#{oid}').brighten(3)"
          say "Okay, unit #{light_name} brightened."
        when "dim"
          api "helper.objectWithOID('#{oid}').dim(3)"
          say "Okay, unit #{light_name} dimmed."
      end
    end

    request_completed
  end

  #Set scene {a|b|c|d} in (the) {room_name}
  listen_for /Scene (a|b|c|d) in(?: the)? (.*)/i do |scene, room_name|
    room_name.strip!
    unit = find_room_unit room_name
  
    if unit.nil?
      say "I couldn't find a room named #{room_name}!"
    else
      oid = unit["oid"]

      case scene.downcase
        when "a"
          api "helper.objectWithOID('#{oid}').setScene(1)"
          say "Setting scene A in the #{room_name}"
        when "b"
          api "helper.objectWithOID('#{oid}').setScene(2)"
          say "Setting scene B in the #{room_name}"
        when "c"
          api "helper.objectWithOID('#{oid}').setScene(3)"
          say "Setting scene C in the #{room_name}"
        when "d"
          api "helper.objectWithOID('#{oid}').setScene(4)"
          say "Setting scene D in the #{room_name}"
      end
    end

    request_completed
  end

  #Query commands

  #What is the outdoor temperature?
  listen_for /what is the outdoor temperature/i do
    outdoor_temp = api "controller.outdoorTemperatureSensor.valueDescription"

    if outdoor_temp.nil?
      say "The outdoor temperature is unavailable!"
    else
      say "The outdoor temperature is #{outdoor_temp}."
    end

    request_completed
  end

  #What is the outdoor humidity?
  listen_for /what is the outdoor humidity/i do
    outdoor_humidity = api "controller.outdoorHumiditySensor.valueDescription"

    if outdoor_humidity.nil?
      say "The outdoor humidity is unavailable!"
    else
      say "The outdoor humidity is #{outdoor_humidity}."
    end

    request_completed
  end

  #What is the {temperature|humidity|heat setpoint|cool setpoint|mode|fan setting} {in|on|at|for} (the) {thermostat_name}?
  listen_for /what is the (temperature|humidity|heat setpoint|cool setpoint|mode|fan setting) (in|on|at|for)(?: the)? (.*)/i do |property,prep,thermostat_name|
    thermostat_name.strip!
    thermostat = find_object_by_name @thermostats, thermostat_name

    if thermostat.nil?
      say "I couldn't find a thermostat named #{thermostat_name}!"
    else
      oid = thermostat["oid"]

      case property.downcase
        when "temperature"
          value = api "helper.objectWithOID('#{oid}').temperatureDescription"
          say "The #{property} #{prep} the #{thermostat_name} is #{value}."
        when "humidity"
          value = api "helper.objectWithOID('#{oid}').humidityDescription"
          say "The #{property} #{prep} the #{thermostat_name} is #{value}."
        when "heat setpoint"
          value = api "helper.objectWithOID('#{oid}').heatSetpointDescription"
          say "The #{property} #{prep} the #{thermostat_name} is #{value}."
        when "cool setpoint"
          value = api "helper.objectWithOID('#{oid}').coolSetpointDescription"
          say "The #{property} #{prep} the #{thermostat_name} is #{value}."
        when "mode"
          value = api "helper.objectWithOID('#{oid}').modeDescription"
          say "The #{property} #{prep} the #{thermostat_name} is #{value}."
        when "fan setting"
          value = api "helper.objectWithOID('#{oid}').fanDescription"
          say "The #{property} #{prep} the #{thermostat_name} is #{value}."
      end
    end

    request_completed
  end

  #What is the {value|high setpoint|low setpoint|} for (the) {sensor_name} sensor?
  listen_for /what is the (value|high setpoint|low setpoint) for(?: the)? (.*) sensor/i do |property,sensor_name|
    sensor_name.strip!
    sensor = find_object_by_name @auxiliary_sensors, sensor_name

    if sensor.nil?
      say "I couldn't find a sensor named #{sensor_name}!"
    else
      oid = sensor["oid"]

      case property.downcase
        when "value"
          value = api "helper.objectWithOID('#{oid}').valueDescription"
          say "The #{property} for the #{sensor_name} sensor is #{value}."
        when "high setpoint"
          value = api "helper.objectWithOID('#{oid}').highSetpointDescription"
          say "The #{property} for the #{sensor_name} sensor is #{value}."
        when "low setpoint"
          value = api "helper.objectWithOID('#{oid}').lowSetpointDescription"
          say "The #{property} for the #{sensor_name} sensor is #{value}."
      end
    end

    request_completed
  end

  #System commands

  listen_for /helper reload/i do
    say "Reloading configuration!"
    reload_configuration

    request_completed
  end

  listen_for /helper status/i do
    status = api "controller.statusDescription"
    say "HaikuHelper control is available, remote helper status is: #{status}"

    request_completed
  end
end
