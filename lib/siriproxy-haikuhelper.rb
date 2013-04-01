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
  listen_for /\b(disarm|arm day instant|arm night delayed|arm day|arm night|arm away|arm vacation)(?: the)? (.*)\b/i do |mode,area_name|
    area = find_object_by_name @areas, area_name
  
    if area.nil?
      say "Sorry, I couldn't find an area named #{area_name}!"
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

  #{Lock|Unlock} all (the|of the) {locks|readers|access control readers}
  listen_for /\b(unlock|lock)(?: the| of the)? (locks|readers|access control readers)\b/i do |action|
    response = ask "Please say your security code to #{action} all locks:"

    if(response.downcase != "cancel")
      case action.downcase
        when "unlock"
          api "controller.lockAllLocks()"
          say "Okay, all locks have been locked"
        when "lock"
          api "controller.unlockAllLocks()"
          say "Okay, all locks have been unlocked"
      end
    else
      say "Sorry, your security code could not be validated."
    end

    request_completed
  end

  #{Lock|Unlock} (the) {reader_name}
  listen_for /\b(unlock|lock)(?: the)? (.*)\b/i do |action,reader_name|
    reader = find_object_by_name @readers, reader_name
  
    if reader.nil?
      say "Sorry, I couldn't find an access control named #{reader_name}!"
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

  #{Bypass|Restore} (the) {zone_name}
  listen_for /\b(bypass|restore)(?: the)? (.*)\b/i do |action,zone_name|
    zone = find_object_by_name @zones, zone_name
  
    if zone.nil?
      say "Sorry, I couldn't find a zone named #{zone_name}!"
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

  #{Macro|Button} {button_name}
  listen_for /\b(?:macro|button) (.*)\b/i do |button_name|
    button = find_object_by_name @buttons, button_name
  
    if button.nil?
      say "Sorry, I couldn't find a button named #{button_name}!"
    else
      response = ask "Are you sure you wish to activate button #{button_name}?"

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

  #All {music|audio|speakers|audio zones} {on|off|mute|unmute}
  listen_for /\ball (?:music|audio|speakers|audio zones) (on|off|mute|unmute)\b/i do |action|
    case action
      when "on"
        api "controller.sendAllAudioZonesOnCommand()"
        say "Okay, all audio zones have been turned on."
      when "off"
        api "controller.sendAllAudioZonesOffCommand()"
        say "Okay, all audio zones have been turned off."
      when "mute"
        api "controller.sendAllAudioZonesMuteCommand()"
        say "Okay, all audio zones have been muted."
      when "unmute"
        api "controller.sendAllAudioZonesUnmuteCommand()"
        say "Okay, all audio zones have been unmuted."
    end

    request_completed
  end

  #{Audio|Music|Speakers|Audio zone} {on|off|mute|unmute} in (the) {audio_zone_name}
  listen_for /\b(?:audio|music|speakers|audio zone) (on|off|mute|unmute) in(?: the)? (.*)\b/i do |action,audio_zone_name|
    audio_zone = find_object_by_name @audio_zones, audio_zone_name
  
    if audio_zone.nil?
      say "Sorry, I couldn't find an audio zone named #{audio_zone_name}!"
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

  #Set the (the) {thermostat_name} {heat setpoint|cool setpoint|humidify setpoint|dehumidify setpoint} to (negative) {0.0-100.0} (degrees|percent)
  listen_for /\bset (?:the )?(.*?) (heat setpoint|cool setpoint|humidify setpoint|dehumidify setpoint) to (-?1?[0-9][0-9]?\.?[0-9]?)/i do |thermostat_name, property, value|
    thermostat = find_object_by_name @thermostats, thermostat_name
  
    if thermostat.nil?
      say "Sorry, I couldn't find a thermostat named #{thermostat_name}!"
    else
      oid = thermostat["oid"]

      units = (property == "heat setpoint" or property == "cool setpoint") ? "degrees" : "percent"
      response = ask "Are you sure you wish to set the #{thermostat_name} #{property} to #{value} #{units}?"

      if(response =~ CONFIRM_REGEX)
        case property.downcase
          when "heat setpoint"
            api "helper.objectWithOID('#{oid}').setHeatSetpoint(#{value.to_f})"
            say "Okay, setting the #{thermostat_name} #{property} to #{value} degrees."
          when "cool setpoint"
            api "helper.objectWithOID('#{oid}').setCoolSetpoint(#{value.to_f})"
            say "Okay, setting the #{thermostat_name} #{property} to #{value} degrees."
          when "humidify setpoint"
            api "helper.objectWithOID('#{oid}').setHumidifySetpoint(#{value.to_i})"
            say "Okay, setting the #{thermostat_name} #{property} to #{value} percent."
          when "dehumidify setpoint"
            api "helper.objectWithOID('#{oid}').setDehumidifySetpoint(#{value.to_i})"
            say "Okay, setting the #{thermostat_name} #{property} to #{value} percent."
        end
      else
        say "Okay, I'll leave it as is."
      end
    end

    request_completed
  end

  #Set the (the) {thermostat_name} fan setting to {automatic|auto|always on|on|cycle}
  listen_for /\bset (?:the )?(.*?) fan setting to (automatic|auto|always on|on|cycle)\b/i do |thermostat_name, value|
    thermostat = find_object_by_name @thermostats, thermostat_name
  
    if thermostat.nil?
      say "Sorry, I couldn't find a thermostat named #{thermostat_name}!"
    else
      oid = thermostat["oid"]

      case value.downcase
        when "automatic", "auto"
          api "helper.objectWithOID('#{oid}').setFan(0)"
          say "Okay, setting the #{thermostat_name} fan setting to #{value}."
        when "always on", "on"
          api "helper.objectWithOID('#{oid}').setFan(1)"
          say "Okay, setting the #{thermostat_name} fan setting to #{value}."
        when "cycle"
          api "helper.objectWithOID('#{oid}').setFan(2)"
          say "Okay, setting the #{thermostat_name} fan setting to #{value}."
      end
    end

    request_completed
  end

  #Set the (the) {sensor_name} {high setpoint|low setpoint} to (negative) {0.0-100.0} (degrees|percent)
  listen_for /\bset (?:the )?(.*?) (high setpoint|low setpoint) to (-?1?[0-9][0-9]?\.?[0-9]?)/i do |sensor_name, property, value|
    sensor = find_object_by_name @auxiliary_sensors, sensor_name
  
    if sensor.nil?
      say "Sorry, I couldn't find a sensor named #{sensor_name}!"
    else
      oid = sensor["oid"]

      units = (sensor["kind"] != 84) ? "degrees" : "percent"
      response = ask "Are you sure you wish to set the #{thermostat_name} #{property} to #{value} #{units}?"

      if(response =~ CONFIRM_REGEX)
        case property.downcase
          when "high setpoint"
            api "helper.objectWithOID('#{oid}').setHighSetpoint(#{value.to_f})"
            say "Okay, setting the #{sensor_name} #{property} to #{value} #{units}."
          when "low setpoint"
            api "helper.objectWithOID('#{oid}').setLowSetpoint(#{value.to_f})"
            say "Okay, setting the #{sensor_name} #{property} to #{value} #{units}."
        end
      else
        say "Okay, I'll leave it as is."
      end
    end

    request_completed
  end

  #All lights {on|off}
  listen_for /\ball lights (on|off)\b/i do |action|
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

  #{Turn on|Turn off|Brighten|Dim} (the) {light_name} (in (the) {room_name})
  listen_for /\b(turn on|turn off|brighten|dim)(?: the )?(.*?)(?: in (?:the )?(.*?))?$/i do |action, light_name, room_name|
    unit = find_light_unit light_name, room_name
  
    if unit.nil?
      if room_name.nil?
        say "Sorry, I couldn't find a unit named #{light_name}!"
      else
        say "Sorry, I couldn't find a unit named #{light_name} in the #{room_name}!"
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
          api "helper.objectWithOID('#{oid}').brighten(2)"
          say "Okay, unit #{light_name} brightened."
        when "dim"
          api "helper.objectWithOID('#{oid}').dim(2)"
          say "Okay, unit #{light_name} dimmed."
      end
    end

    request_completed
  end

  #Set (the) {light_name} (in (the) {room_name}) to {0-100}
  listen_for /\bset(?: the)? (.*?)(?: in (?:the )?(.*?))? to (1?[0-9][0-9]?)$/i do |light_name, room_name, percent|
    unit = find_light_unit light_name, room_name
  
    if unit.nil?
      if room_name.nil?
        say "Sorry, I couldn't find a unit named #{light_name}!"
      else
        say "Sorry, I couldn't find a unit named #{light_name} in the #{room_name}!"
      end
    else
      oid = unit["oid"]

      api "helper.objectWithOID('#{oid}').setLevel(#{percent.to_i})"
      say "Okay, unit #{light_name} in the #{room_name} has been set to #{percent}%."
    end

    request_completed
  end

  #Set scene {a|b|c|d} in (the) {room_name}
  listen_for /\bscene (a|b|c|d) in(?: the)? (.*)/i do |scene, room_name|
    unit = find_room_unit room_name
  
    if unit.nil?
      say "Sorry, I couldn't find a room named #{room_name}!"
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

  #What is the energy cost?
  listen_for /\bwhat is the energy cost\b/i do
    cost = api "controller.energyCostDescription"
    say "The current energy cost is: #{cost}"

    request_completed
  end

  #What is the {area_name} area {status|mode}?
  listen_for /\bwhat is the (.*?) area (?:status|mode)\b/i do |area_name|
    area = find_object_by_name @areas, area_name
  
    if area.nil?
      say "Sorry, I couldn't find an area named #{area_name}!"
    else
      oid = area["oid"]

      status = api "helper.objectWithOID('#{oid}').statusDescription"
      mode = api "helper.objectWithOID('#{oid}').modeDescription"
      say "The #{area_name} is set to #{mode} with status: #{status}."
    end

    request_completed
  end

  #What is the {zone_name} zone status?
  listen_for /\bwhat is the (.*?) zone status\b/i do |zone_name|
    zone = find_object_by_name @zones, zone_name
  
    if zone.nil?
      say "Sorry, I couldn't find an zone named #{zone_name}!"
    else
      oid = zone["oid"]

      status = api "helper.objectWithOID('#{oid}').statusDescription"
      say "The #{zone_name} zone status is: #{status}."
    end

    request_completed
  end

  #What is the outdoor temperature?
  listen_for /\bwhat is the outdoor temperature\b/i do
    outdoor_temp = api "controller.outdoorTemperatureSensor.valueDescription"

    if outdoor_temp.nil?
      say "The outdoor temperature is unavailable!"
    else
      say "The outdoor temperature is #{outdoor_temp}."
    end

    request_completed
  end

  #What is the outdoor humidity?
  listen_for /\bwhat is the outdoor humidity\b/i do
    outdoor_humidity = api "controller.outdoorHumiditySensor.valueDescription"

    if outdoor_humidity.nil?
      say "The outdoor humidity is unavailable!"
    else
      say "The outdoor humidity is #{outdoor_humidity}."
    end

    request_completed
  end

  #What is the {temperature|humidity|heat setpoint|cool setpoint|humidify setpoint|dehumidify setpoint|mode|fan setting} {in|on|at|for} (the) {thermostat_name}?
  listen_for /\bwhat is the (temperature|humidity|heat setpoint|cool setpoint|humidify setpoint|dehumidify setpoint|mode|fan setting) (in|on|at|for)(?: the)? (.*)\b/i do |property,prep,thermostat_name|
    thermostat = find_object_by_name @thermostats, thermostat_name

    if thermostat.nil?
      say "Sorry, I couldn't find a thermostat named #{thermostat_name}!"
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
        when "humidify setpoint"
          value = api "helper.objectWithOID('#{oid}').humidifySetpointDescription"
          say "The #{property} #{prep} the #{thermostat_name} is #{value}."
        when "dehumidify setpoint"
          value = api "helper.objectWithOID('#{oid}').dehumidifySetpointDescription"
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

  #What is the {value|high setpoint|low setpoint} for (the) {sensor_name}?
  listen_for /\bwhat is the (value|high setpoint|low setpoint) for(?: the)? (.*)\b/i do |property,sensor_name|
    sensor = find_object_by_name @auxiliary_sensors, sensor_name

    if sensor.nil?
      say "Sorry, I couldn't find a sensor named #{sensor_name}!"
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

  #System notices
  listen_for /\bsystem notices\b/i do
    notices = api "controller.notices()"
    say "The current system notices are: #{notices.join(". ")}."

    request_completed
  end

  #System status
  listen_for /\bsystem status\b/i do
    status = api "controller.statusDescription"
    version = api "helper.version"
    say "HaikuHelper control is available, remote helper version is: #{version}, status is: #{status}"

    request_completed
  end

  #Helper reload
  listen_for /\bhelper reload\b/i do
    say "Reloading configuration!"
    reload_configuration

    request_completed
  end
end
