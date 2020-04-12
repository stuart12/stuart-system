def key_mapping
  ::File
    .readlines('/usr/include/linux/input-event-codes.h')
    .map { |l| /#define\s+KEY_(\w+)\s+((0x)?\h+)/.match(l) }
    .select { |m| m }.map { |m| [m[1], Integer(m[2])] }
    .to_h
end

NUMLOCK_MAPPING =
  {
    KP0: 'INSERT',
    KP1: 'END',
    KP2: 'DOWN',
    KP3: 'PAGEDOWN',
    KP4: 'LEFT',
    KP6: 'RIGHT',
    KP7: 'HOME',
    KP8: 'UP',
    KP9: 'PAGEUP',
    KPDOT: 'DELETE',
  }.freeze

ALL_MUTED = "
{% for i in states.media_player if i.state == 'on' and is_state_attr('media_player.' + i.name, 'is_volume_muted', False) %}
f
{% else %}
true
{% endfor %}
".delete("\n")

def _trigger(key)
  code = _keycode(key)
  return nil unless code

  {
    platform: 'event',
    event_type: 'keyboard_remote_command_received',
    event_data: {
      key_code: code,
    },
  }
end

def _keypad(key)
  keycode("KP#{key}")
end

def network_host
  StuartConfig::Helpers::CfgHelper.config['networking']['hosts'].keys.sort
end

# helpers to build a home assistant configuration
class Hass
  @mapping = nil
  def self.mapping
    @mapping ||= key_mapping
  end

  def self.all_snapcast_clients_muted
    ALL_MUTED
  end

  def self._keycode(key)
    mapping[key.to_s.upcase]
  end

  def self.trigger_for_key(key)
    kp = "KP#{key}".upcase
    [key, kp, NUMLOCK_MAPPING[kp.to_sym]].reject(&:nil?).map { |k| _trigger(k) }.compact
  end

  def self.automation_for_key(alias_name, key, actions, cfg = {})
    automation_general(
      "#{alias_name} (#{key})",
      trigger: trigger_for_key(key),
      action: actions,
      **cfg,
    )
  end

  def self.automation_general(alias_name, cfg)
    a = StuartConfig::Helpers::CfgHelper.set_config['homeassistant']['automation'][alias_name]
    cfg.each { |k, v| a[k] = v }
  end

  def self.automation(alias_name, one, two, opt = nil)
    if opt.nil?
      automation_general(alias_name, trigger: one, action: two)
    else
      automation_general(alias_name, trigger: one, condition: two, action: opt)
    end
  end

  def self.script(name, sequence, cfg = {})
    StuartConfig::Helpers::CfgHelper.attributes(
      ['homeassistant', 'script', name],
      cfg.merge(sequence: sequence),
    )
  end

  def self.hide(type, name)
    attributes(['configuration', 'homeassistant', 'customize', "#{type}.#{name}", 'hidden'], true)
  end

  def self.attributes(where, cfg)
    StuartConfig::Helpers::CfgHelper.attributes(['homeassistant'] + where, cfg)
  end

  def self.shell_commands(commands)
    commands.each do |name, cmd|
      StuartConfig::Helpers::CfgHelper.set_config['homeassistant']['shell_command'][name] = cmd
    end
  end

  def self.template_sensor(name, template, cfg = {})
    StuartConfig::Helpers::CfgHelper.attributes(['homeassistant', 'template_sensor', name], cfg.merge(value_template: template))
  end

  def self.binary_template_sensor(name, template, cfg = {})
    attributes(['binary_template_sensor', name], cfg.merge(value_template: template))
  end

  def self.sensor(name, platform, cfg)
    StuartConfig::Helpers::CfgHelper.attributes(['homeassistant', 'sensor', name], cfg.merge(platform: platform))
  end

  def self.binary_sensor(name, platform, cfg)
    StuartConfig::Helpers::CfgHelper.attributes(['homeassistant', 'binary_sensor', name], cfg.merge(platform: platform))
  end

  def self.history_graph(name, cfg)
    StuartConfig::Helpers::CfgHelper.attributes(['homeassistant', 'history_graph', name], cfg)
  end

  def self.media_player(name, cfg)
    StuartConfig::Helpers::CfgHelper.attributes(['homeassistant', 'media_player', name], cfg)
  end

  def self.switch(platform, id, cfg)
    StuartConfig::Helpers::CfgHelper.set_config['homeassistant']['switch'][platform][id] = cfg
  end

  def self.mute_actions(hosts: network_hosts, mute: true)
    # FIXME: send mqtt asking client to stop
    hosts.sort.map do |name|
      { service: 'media_player.volume_mute',
        data: {
          entity_id: "media_player.snapcast_client_#{name}",
          is_volume_muted: mute,
        } }
    end
  end

  def self.configure(cfg)
    StuartConfig::Helpers::CfgHelper.attributes(
      %w[homeassistant],
      configuration: cfg,
    )
  end

  def self.snapcast_playing_entity_id
    'binary_sensor.snapcast_playing'
  end

  def self.snapcast_groups_playing(playing)
    {
      platform: 'state',
      entity_id: snapcast_playing_entity_id,
      to: playing ? 'on' : 'off',
    }
  end
end

KeyCodes = Hass # old name
