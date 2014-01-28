require 'cora'
require 'siri_objects'
require 'pp'
require 'haikuhelper'


class SiriProxy::Plugin::HaikuHelper < SiriProxy::Plugin
  OBJECT = "(?:the )?(.*?)"
  OBJECT_GREEDY = "(?:the )?(.*)"
  SIRI_NUMBER_WORDS = "zero|one|two|three|four|five|six|seven|eight|nine"
  DURATION = "(1?[0-9]?[0-9]|#{SIRI_NUMBER_WORDS})"
  DURATION_UNIT = "(seconds|minutes|hours)"
  PERCENTAGE = "(1?[0-9]?[0-9]|#{SIRI_NUMBER_WORDS})"
  TEMPERATURE = "(-?1?[0-9]?[0-9]\.?[0-9]?|#{SIRI_NUMBER_WORDS})"
  SECURITY_MODE = "(day|night|away|vacation|day instant|night delayed)(?: mode)?"

  def initialize(config)
    if config["url"].nil?
      puts "[Error - HaikuHelper] Missing configuration, please define url, controller_name and password in your config.yml file." 
    else
      @helper = HaikuHelperAPI.new config["url"], config["controller_name"], config["password"]
      reload_configuration
    end
  end

  #HH API shorthand
  def api(cmd)
    @helper.api(cmd)
  end

  #Reloads configuration from the HaikuHelper server
  def reload_configuration
    puts "[Info - HaikuHelper] Reloading HaikuHelper configuration..."

    if api("helper.version").to_f < 2.90
      puts "[Error - HaikuHelper] HaikuHelper 2.90 or later is required for siriproxy-haikuhelper to work!"
    end

    @readers = api "controller.accessControlReaders"
    @areas = api "controller.areas"
    @audio_sources = api "controller.audioSources"
    @audio_zones = api "controller.audioZones"
    @auxiliary_sensors = api "controller.auxiliarySensors"
    @buttons = api "controller.buttons"
    @thermostats = api "controller.thermostats"
    @units = api "controller.units"
    @zones = api "controller.zones"
  end

  #Helper methods

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

  #Validate a security code
  def validate_security_code(code, area_number = 0)
    if code.match /[0-9][0-9][0-9][0-9]/
      api "controller.validateCodeSynchronously('#{code}', #{area_number})"
    else
      0
    end
  end

  #Parses a siri number
  def parse_siri_number(number)
    case number
    when "zero"  then 0
    when "one"   then 1
    when "two"   then 2
    when "three" then 3
    when "four"  then 4
    when "five"  then 5
    when "six"   then 6
    when "seven" then 7
    when "eight" then 8
    when "nine"  then 9
    else         number.to_i
    end
  end

  #Control commands

  #Disarm (all areas)
  listen_for /\bdisarm(?: all areas)?$/i do
    response = ask "Please say your security code to disarm all areas:"

    if(validate_security_code(response) > 0)
      api "controller.setAllAreasToMode(0)"
      say "Okay, all areas disarmed!"
    else
      say "Sorry, your security code could not be validated."
    end

    request_completed
  end

  #Disarm (the) {area_name}
  listen_for /\bdisarm #{OBJECT_GREEDY}\b/i do |area_name|
    area = find_object_by_name @areas, area_name

    if area.nil?
      say "Sorry, I couldn't find an area named #{area_name}!"
    else
      response = ask "Please say your security code to disarm all areas:"

      if(validate_security_code(response, area["number"]) > 0)
        oid = area["oid"]

        api "helper.objectWithOID('#{oid}').setMode(0)"
        say "Okay, the #{area_name} area has been disarmed!"
      else
        say "Sorry, your security code could not be validated."
      end
    end

    request_completed
  end

  #Arm (all areas) (in) {day instant|night delayed|day|night|away|vacation} (mode)
  listen_for /\barm(?: all areas)?(?: in)? #{SECURITY_MODE}\b/i do |mode|
    response = ask "Please say your security code to #{mode} all areas:"

    if(validate_security_code(response) > 0)
      case mode.downcase
      when "day"
        api "controller.setAllAreasToMode(1)"
      when "night"
        api "controller.setAllAreasToMode(2)"
      when "away"
        api "controller.setAllAreasToMode(3)"
      when "vacation"
        api "controller.setAllAreasToMode(4)"
      when "day instant"
        api "controller.setAllAreasToMode(5)"
      when "night delayed"
        api "controller.setAllAreasToMode(6)"
      end
      say "Okay, arming all areas in #{mode} mode..."
    else
      say "Sorry, your security code could not be validated."
    end

    request_completed    
  end

  #Arm (the) {area_name} (in) {day instant|night delayed|day|night|away|vacation} (mode)
  listen_for /\barm #{OBJECT}(?: in)? #{SECURITY_MODE}\b/i do |mode, area_name|
    area = find_object_by_name @areas, area_name
  
    if area.nil?
      say "Sorry, I couldn't find an area named #{area_name}!"
    else
      response = ask "Please say your security code to #{mode} the #{area_name}:"

      if(validate_security_code(response, area["number"]) > 0)
        oid = area["oid"]

        case mode.downcase
        when "day"
          api "helper.objectWithOID('#{oid}').setMode(1)"
        when "night"
          api "helper.objectWithOID('#{oid}').setMode(2)"
        when "away"
          api "helper.objectWithOID('#{oid}').setMode(3)"
        when "vacation"
          api "helper.objectWithOID('#{oid}').setMode(4)"
        when "day instant"
          api "helper.objectWithOID('#{oid}').setMode(5)"
        when "night delayed"
          api "helper.objectWithOID('#{oid}').setMode(6)"
        end
        say "Arming the #{area_name} in #{mode} mode..."
      else
        say "Sorry, your security code could not be validated."
      end
    end

    request_completed
  end

  #{Lock|Unlock} all (the|of the) {locks|readers|access control readers}
  listen_for /\b(unlock|lock) all (?: the| of the)? (locks|readers|access control readers)\b/i do |action|
    response = ask "Please say your security code to #{action} all locks:"

    if(validate_security_code(response) > 0)
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
  listen_for /\b(unlock|lock) #{OBJECT_GREEDY}\b/i do |action,reader_name|
    reader = find_object_by_name @readers, reader_name
  
    if reader.nil?
      say "Sorry, I couldn't find an access control named #{reader_name}!"
    else
      response = ask "Please say your security code to #{action} the #{reader_name}:"

      if(validate_security_code(response) > 0)
        oid = reader["oid"]

        case action.downcase
        when "unlock"
          api "helper.objectWithOID('#{oid}').unlock()"
          say "Okay, the #{reader_name} has been unlocked."
        when "lock"
          api "helper.objectWithOID('#{oid}').lock()"
          say "Okay, the #{reader_name} has been locked."
        end
      else
        say "Sorry, your security code could not be validated."
      end
    end

    request_completed
  end

  #{Bypass|Restore} (the) {zone_name}
  listen_for /\b(bypass|restore) #{OBJECT_GREEDY}\b/i do |action,zone_name|
    zone = find_object_by_name @zones, zone_name
  
    if zone.nil?
      say "Sorry, I couldn't find a zone named #{zone_name}!"
    else
      response = ask "Please say your security code to #{action} the #{zone_name}:"

      if(validate_security_code(response, zone["area"]) > 0)
        oid = zone["oid"]

        case action.downcase
        when "bypass"
          api "helper.objectWithOID('#{oid}').bypass()"
          say "Okay, the #{zone_name} has been bypassed."
        when "restore"
          api "helper.objectWithOID('#{oid}').restore()"
          say "Okay, the #{zone_name} has been restored."
        end
      else
        say "Sorry, your security code could not be validated."
      end
    end

    request_completed
  end

  #(Run) (the) {button_name} {button|macro}
  listen_for /\b(?:run )?#{OBJECT} (?:button|macro)\b/i do |button_name|
    button = find_object_by_name @buttons, button_name
  
    if button.nil?
      say "Sorry, I couldn't find a button named #{button_name}!"
    else
      response = ask "Are you sure you wish to activate button #{button_name}?"

      if response =~ CONFIRM_REGEX
        oid = button["oid"]
        api "helper.objectWithOID('#{oid}').activate()"
        say "Okay, button #{button_name} activated."
      else
        say "Alright, I won't activate it."
      end
    end

    request_completed
  end

  #{Turn on|Turn off|Mute|Unmute} all audio (zones)
  listen_for /\b(turn on|turn off|mute|unmute) all audio(?: zones)?\b/i do |action|
    case action.downcase
    when "turn on"
      api "controller.sendAllAudioZonesOnCommand()"
      say "Okay, all audio zones have been turned on."
    when "turn off"
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

  #{Turn on|Turn off|Mute|Unmute|Rewind|Previous|Repeat|Skip|Next|Forward|Play|Pause|Unpause} (the) {audio|music|song|track} in (the) {audio_zone_name}
  listen_for /\b(turn on|turn off|mute|unmute|rewind|previous|last|skip|next|forward|play|pause|unpause) (?:the )?(?:audio|music|song|track) in #{OBJECT_GREEDY}\b/i do |action,audio_zone_name|
    audio_zone = find_object_by_name @audio_zones, audio_zone_name
  
    if audio_zone.nil?
      say "Sorry, I couldn't find an audio zone named #{audio_zone_name}!"
    else
      oid = audio_zone["oid"]

      case action.downcase
      when "turn on"
        api "helper.objectWithOID('#{oid}').on()"
        say "Okay, the #{audio_zone_name} audio zone has been turned on."
      when "turn off"
        api "helper.objectWithOID('#{oid}').off()"
        say "Okay, the #{audio_zone_name} audio zone has been turned off."
      when "mute"
        api "helper.objectWithOID('#{oid}').mute()"
        say "Okay, the #{audio_zone_name} audio zone has been muted."
      when "unmute"
        api "helper.objectWithOID('#{oid}').unmute()"
        say "Okay, the #{audio_zone_name} audio zone has been unmuted."
      when "rewind", "previous", "repeat"
        api "helper.objectWithOID('#{oid}').sendCommandForFeature('HAIAudioZoneFeatureRewindButton')"
        say "Okay, I've sent the '#{action}' command to the #{audio_zone_name} audio zone."
      when "skip", "next", "forward"
        api "helper.objectWithOID('#{oid}').sendCommandForFeature('HAIAudioZoneFeatureForwardButton')"
        say "Okay, I've sent the '#{action}' command to the #{audio_zone_name} audio zone."
      when "play", "pause", "unpause"
        api "helper.objectWithOID('#{oid}').sendCommandForFeature('HAIAudioZoneFeaturePlayPauseButton')"
        say "Okay, I've sent the '#{action}' command to the #{audio_zone_name} audio zone."
      end
    end

    request_completed
  end

  #{Set|Change} (the) {audio_zone_name} source to (the) {audio_source_name}
  listen_for /\b(?:set|change) #{OBJECT} source to #{OBJECT_GREEDY}\b/i do |audio_zone_name,audio_source_name|
    audio_source = find_object_by_name @audio_zones, audio_source_name
    audio_zone = find_object_by_name @audio_zones, audio_zone_name
  
    if audio_zone.nil?
      say "Sorry, I couldn't find an audio zone named #{audio_zone_name}!"
    elsif audio_source.nil?
      say "Sorry, I couldn't find an audio source named #{audio_source_name}!"
    else
      oid = audio_zone["oid"]

      api "helper.objectWithOID('#{oid}').setSource(#{audio_source['number']})"
      say "Okay, the #{audio_zone_name} audio zone source has been set to #{audio_source_name}."
    end

    request_completed
  end

  #{Set|Change} (the) {audio_zone_name} volume to {0-100} (percent)
  listen_for /\b(?:set|change) #{OBJECT} volume to #{PERCENTAGE}/i do |audio_zone_name, percent|
    audio_zone = find_object_by_name @audio_zones, audio_zone_name
  
    if audio_zone.nil?
      say "Sorry, I couldn't find an audio zone named #{light_name}!"
    else
      oid = audio_zone["oid"]
      percent = parse_siri_number(percent)

      api "helper.objectWithOID('#{oid}').setVolume(#{percent.to_i})"
      say "Okay, the #{light_name} audio volume has been set to #{percent}%."
    end

    request_completed
  end

  #{Set|Change} (the) {thermostat_name} {heat setpoint|cool setpoint|humidify setpoint|dehumidify setpoint} to (negative) {0.0-100.0} (degrees|percent)
  listen_for /\b(?:set|change) #{OBJECT} (heat setpoint|cool setpoint|humidify setpoint|dehumidify setpoint) to #{TEMPERATURE}/i do |thermostat_name, property, value|
    thermostat = find_object_by_name @thermostats, thermostat_name
  
    if thermostat.nil?
      say "Sorry, I couldn't find a thermostat named #{thermostat_name}!"
    else
      oid = thermostat["oid"]
      value = parse_siri_number(value)

      units = (property == "heat setpoint" or property == "cool setpoint") ? "degrees" : "percent"
      response = ask "Are you sure you wish to set the #{thermostat_name} #{property} to #{value} #{units}?"

      if response =~ CONFIRM_REGEX
        case property.downcase
        when "heat setpoint"
          api "helper.objectWithOID('#{oid}').setHeatSetpoint(#{value.to_f})"
        when "cool setpoint"
          api "helper.objectWithOID('#{oid}').setCoolSetpoint(#{value.to_f})"
        when "humidify setpoint"
          api "helper.objectWithOID('#{oid}').setHumidifySetpoint(#{value.to_i})"
        when "dehumidify setpoint"
          api "helper.objectWithOID('#{oid}').setDehumidifySetpoint(#{value.to_i})"
        end
        say "Okay, setting the #{thermostat_name} #{property} to #{value} percent."
      else
        say "Okay, I'll leave it as is."
      end
    end

    request_completed
  end

  #{Set|Change} the (the) {thermostat_name} fan setting to {automatic|auto|always on|on|cycle}
  listen_for /\bset #{OBJECT} fan setting to (automatic|auto|always on|on|cycle)\b/i do |thermostat_name, value|
    thermostat = find_object_by_name @thermostats, thermostat_name
  
    if thermostat.nil?
      say "Sorry, I couldn't find a thermostat named #{thermostat_name}!"
    else
      oid = thermostat["oid"]

      case value.downcase
      when "automatic", "auto"
        api "helper.objectWithOID('#{oid}').setFan(0)"
      when "always on", "on"
        api "helper.objectWithOID('#{oid}').setFan(1)"
      when "cycle"
        api "helper.objectWithOID('#{oid}').setFan(2)"
      end
      say "Okay, setting the #{thermostat_name} fan setting to #{value}."
    end

    request_completed
  end

  #{Set|Change} the (the) {thermostat_name} hold setting to {on|off}
  listen_for /\b(?:set|change) #{OBJECT} hold setting to (on|off)\b/i do |thermostat_name, value|
    thermostat = find_object_by_name @thermostats, thermostat_name
  
    if thermostat.nil?
      say "Sorry, I couldn't find a thermostat named #{thermostat_name}!"
    else
      oid = thermostat["oid"]

      case value.downcase
      when "on"
        api "helper.objectWithOID('#{oid}').setHold(0)"
      when "off"
        api "helper.objectWithOID('#{oid}').setHold(1)"
      end
      say "Okay, setting the #{thermostat_name} hold setting to #{value}."
    end

    request_completed
  end

  #{Set|Change} the (the) {sensor_name} {high setpoint|low setpoint} to (negative) {0.0-100.0} (degrees|percent)
  listen_for /\b(?:set|change) #{OBJECT} (high setpoint|low setpoint) to #{TEMPERATURE}/i do |sensor_name, property, value|
    sensor = find_object_by_name @auxiliary_sensors, sensor_name
  
    if sensor.nil?
      say "Sorry, I couldn't find a sensor named #{sensor_name}!"
    else
      oid = sensor["oid"]
      value = parse_siri_number(value)

      units = (sensor["kind"] != 84) ? "degrees" : "percent"
      response = ask "Are you sure you wish to set the #{thermostat_name} #{property} to #{value} #{units}?"

      if response =~ CONFIRM_REGEX
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

  #(Turn) all lights {on|off}
  listen_for /\b(?:turn )?all lights (on|off)\b/i do |action|
    response = ask "Are you sure you want to turn #{action} all of the lights?"

    if response =~ CONFIRM_REGEX
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

  #{Turn on|Turn off|Brighten|Dim} (the) {light_name} (in (the) {room_name}) (for {1-60} {seconds|minutes|hours})
  listen_for /\b(turn on|turn off|brighten|dim) #{OBJECT}(?: in #{OBJECT})?(?: for #{DURATION} #{DURATION_UNIT})?$/i do |action, light_name, room_name, duration, duration_unit|
    unit = find_light_unit light_name, room_name
  
    if unit.nil?
      if room_name.nil?
        say "Sorry, I couldn't find a unit named #{light_name}!"
      else
        say "Sorry, I couldn't find a unit named #{light_name} in the #{room_name}!"
      end
    else
      oid = unit["oid"]
      duration = parse_siri_number(duration)

      case action.downcase
      when "turn on"
        case duration_unit
        when "seconds"
          if 1 <= duration && duration <= 99
            api "helper.objectWithOID('#{oid}').setOnForSeconds(#{duration})"
            say "Okay, unit #{light_name} turned on for #{duration} #{duration_unit}."
          else
            say "Sorry, I can only set a timer for 1 to 99 seconds, 1 to 99 minutes or 1 to 18 hours."
          end
        when "minutes"
          if 1 <= duration && duration <= 99
            api "helper.objectWithOID('#{oid}').setOnForMinutes(#{duration})"
            say "Okay, unit #{light_name} turned on for #{duration} #{duration_unit}."
          else
            say "Sorry, I can only set a timer for 1 to 99 seconds, 1 to 99 minutes or 1 to 18 hours."
          end
        when "hours"
          if 1 <= duration && duration <= 18
            api "helper.objectWithOID('#{oid}').setOnForHours(#{duration})"
            say "Okay, unit #{light_name} turned on for #{duration} #{duration_unit}."
          else
            say "Sorry, I can only set a timer for 1 to 99 seconds, 1 to 99 minutes or 1 to 18 hours."
          end
        else
          api "helper.objectWithOID('#{oid}').on()"
          say "Okay, unit #{light_name} turned on."
        end
      when "turn off"
        case duration_unit
        when "seconds"
          if 1 <= duration && duration <= 99
            api "helper.objectWithOID('#{oid}').setOffForSeconds(#{duration})"
            say "Okay, unit #{light_name} turned off for #{duration} #{duration_unit}."
          else
            say "Sorry, I can only set a timer for 1 to 99 seconds, 1 to 99 minutes or 1 to 18 hours."
          end
        when "minutes"
          if 1 <= duration && duration <= 99
            api "helper.objectWithOID('#{oid}').setOffForMinutes(#{duration})"
            say "Okay, unit #{light_name} turned off for #{duration} #{duration_unit}."
          else
            say "Sorry, I can only set a timer for 1 to 99 seconds, 1 to 99 minutes or 1 to 18 hours."
          end
        when "hours"
          if 1 <= duration && duration <= 18
            api "helper.objectWithOID('#{oid}').setOffForHours(#{duration})"
            say "Okay, unit #{light_name} turned off for #{duration} #{duration_unit}."
          else
            say "Sorry, I can only set a timer for 1 to 99 seconds, 1 to 99 minutes or 1 to 18 hours."
          end
        else
          api "helper.objectWithOID('#{oid}').off()"
          say "Okay, unit #{light_name} turned off."
        end
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

  #{Set|Change} (the) {light_name} (level) (in (the) {room_name}) to {0-100} (percent)
  listen_for /\b(?:set|change) (?: the)?(.*?)(?: level)?(?: in(?: the)?(.*?))? to #{PERCENTAGE}/i do |light_name, room_name, percent|
    unit = find_light_unit light_name, room_name
  
    if unit.nil?
      if room_name.nil?
        say "Sorry, I couldn't find a unit named #{light_name}!"
      else
        say "Sorry, I couldn't find a unit named #{light_name} in the #{room_name}!"
      end
    else
      oid = unit["oid"]
      percent = parse_siri_number(percent)

      api "helper.objectWithOID('#{oid}').setLevel(#{percent.to_i})"
      if room_name.nil?
        say "Okay, unit #{light_name} has been set to #{percent}%."
      else
        say "Okay, unit #{light_name} in the #{room_name} has been set to #{percent}%."
      end
    end

    request_completed
  end

  #{Set|Change} (the) {room_name} scene to {a|b|c|d|one|two|three|four}
  listen_for /\b(?:set|change) #{OBJECT} scene to (a|b|c|d|one|two|three|four)\b/i do |room_name,scene|
    unit = find_room_unit room_name
  
    if unit.nil?
      say "Sorry, I couldn't find a room named #{room_name}!"
    else
      oid = unit["oid"]

      case scene.downcase
      when "a", "one"
        api "helper.objectWithOID('#{oid}').setScene(1)"
        say "Setting scene A in the #{room_name}"
      when "b", "two"
        api "helper.objectWithOID('#{oid}').setScene(2)"
        say "Setting scene B in the #{room_name}"
      when "c", "three"
        api "helper.objectWithOID('#{oid}').setScene(3)"
        say "Setting scene C in the #{room_name}"
      when "d", "four"
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

  #What is (the) {area_name} area {status|mode}?
  listen_for /\bwhat is #{OBJECT} area (?:status|mode)\b/i do |area_name|
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
  listen_for /\bwhat is #{OBJECT} zone status\b/i do |zone_name|
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
  listen_for /\bwhat is the (temperature|humidity|heat setpoint|cool setpoint|humidify setpoint|dehumidify setpoint|mode|fan setting) (in|on|at|for) #{OBJECT_GREEDY}\b/i do |property,prep,thermostat_name|
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
  listen_for /\bwhat is the (value|high setpoint|low setpoint) for #{OBJECT_GREEDY}\b/i do |property,sensor_name|
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

  #What time is (the) {sunrise|sunset} (time)?
  listen_for /\bwhat time is(?: the)? (sunrise|sunset)(?: time)?\b/i do |property|
    sunrise = api "controller.#{property}Description"
    say "The #{property} will begin at #{sunrise}."

    request_completed
  end

  #System commands

  #System status
  listen_for /\bsystem status\b/i do
    status = api "controller.statusDescription"
    troubles = api "controller.troubles.troublesDescription"
    @areas = api "controller.areas"

    area_statuses = @areas.map { |area| area = "#{area["bestDescription"]} status: #{area["alarmsDescription"]}, mode: #{area["modeDescription"]}." }

    say "Connection status: #{status}. Troubles: #{troubles}. #{area_statuses.join(' ')}"

    request_completed
  end

  #System notices
  listen_for /\bsystem notices\b/i do
    notices = api "controller.notices()"
    say "The current system notices are: #{notices.join(". ")}."

    request_completed
  end

  #System messages
  listen_for /\bsystem messages\b/i do
    @messages = api "controller.messages"

    unread_messages = @messages.select { |message| message["isUnacknowledged"] }
    unread_messages.map! { |message| message = message["bestDescription"] }

    unless unread_messages.count == 0
      say "The unacknowledged system messages are: #{unread_messages.join(', ')}."
    else
      say "There are no unacknowledged messages."
    end

    request_completed
  end

  #Helper status
  listen_for /\bhelper status\b/i do
    status = api "controller.statusDescription"
    version = api "helper.version"
    say "HaikuHelper control is available, remote helper version is: #{version}, status is: #{status}."

    request_completed
  end

  #Helper send notification
  listen_for /\bhelper send notification\b/i do
    response = ask "What would you like the notification to say?"

    if response != "cancel"
      api "helper.sendNotification(controller, \"#{response} (sent via Siri)\")"
      say "Notification sent."
    else
      say "Okay, cancelled."
    end

    request_completed
  end

  #Helper reload
  listen_for /\bhelper reload\b/i do
    say "Reloading HaikuHelper configuration!"
    reload_configuration

    request_completed
  end
end
