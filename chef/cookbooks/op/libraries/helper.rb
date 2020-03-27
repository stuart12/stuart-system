# helpers to build a home assistant configuration
class Hass
  @mapping = nil
  @numlock = {
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
  }
  def self.mapping
    if @mapping.nil?
      @mapping =
        ::File
        .readlines('/usr/include/linux/input-event-codes.h')
        .map { |l| /#define\s+KEY_(\w+)\s+((0x)?\h+)/.match(l) }
        .select { |m| m }.map { |m| [m[1], Integer(m[2])] }
        .to_h
    end
    @mapping
  end

  def self._keypad(key)
    keycode("KP#{key}")
  end

  def self._keycode(key)
    k = key.to_s.upcase
    mapping[k]
  end

  def self._trigger(key)
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

  def self.trigger_for_key(key)
    kp = "KP#{key}".upcase
    [key, kp, @numlock[kp.to_sym]].reject(&:nil?).map { |k| _trigger(k) }.compact
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

  def self.automation(alias_name, trigger, actions)
    automation_general(alias_name, trigger: trigger, action: actions)
  end

  def self.script(name, sequence)
    StuartConfig::Helpers::CfgHelper.set_config['homeassistant']['script'][name].tap do |a|
      a['sequence'] = sequence
    end
  end

  def self.shell_command(commands)
    commands.each do |name, cmd|
      StuartConfig::Helpers::CfgHelper.set_config['homeassistant']['shell_command'][name] = cmd
    end
  end

  def self.sensor(name, platform, cfg)
    StuartConfig::Helpers::CfgHelper.set_config['homeassistant']['sensor'][name] = cfg.merge(platform: platform)
  end

  def self.switch(platform, id, cfg)
    StuartConfig::Helpers::CfgHelper.set_config['homeassistant']['switch'][platform][id] = cfg
  end

  def self.hosts
    StuartConfig::Helpers::CfgHelper.config['networking']['hosts'].keys.sort
  end

  def self.mute_actions(hosts: Hass.hosts, mute: true)
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
end

KeyCodes = Hass # old name

# https://medium.com/@mearns.b/attributes-are-dead-long-live-helper-libraries-e936513793cc
# A helper class for encapsulating information about the installation and configuration of the app.
module StuartConfig
  # My Helpers
  module Helpers
    # Just for the namespace
    module CfgHelper
      BASE = 'stuart'.freeze

      module_function

      def node
        is_a?(::Chef::Node) ? self : ::Chef.node
      end

      def base
        'stuart'
      end

      def set_config
        node.default[BASE]['config']
      end

      def secrets
        node['secrets']
      end

      def config(*where)
        where.flatten.inject(node[BASE]['config']) { |w, k| w[k] || {} }
      end

      def add_package(name)
        node.default[BASE]['config']['packages']['install'][name] = true
      end

      def systemd_unit(name, content)
        attributes(['systemd', 'units', name, 'content'], content)
      end

      def activate(name)
        (name.respond_to?(:each) ? name : [name]).each do |n|
          set_config[n]['activate'] = true
        end
      end

      def my_repo(name)
        attributes(['git', 'hosts', 'github.com', 'users', 'stuart12', 'repos', name], true)
      end

      def activated?(name)
        (config[name] || {})['activate']
      end

      def workstation
        config['workstation']
      end

      def network
        networking = config['networking'] || {}
        gateway = networking['gateway']
        mask = networking['mask']
        return nil unless gateway && mask

        IPAddr.new("#{gateway}/#{mask}")
      end

      def self.attributes(where, cfg)
        configure(cfg, where, node.default)
      end

      def self.override(where, cfg)
        configure(cfg, where, node.override)
      end

      def users
        (config['users']['users'] || {}).select { |_, cfg| cfg['name'] }
      end

      private_class_method def self.configure(cfg, where, level)
        start = cfg_start + where
        last = start.pop
        _configure({ last => cfg }, start.inject(level) { |w, k| w[k] })
        where.inject(config) { |w, k| w[k] }
      end

      private_class_method def self.cfg_start
        [BASE, 'config']
      end

      private_class_method def self._configure(cfg, where)
        cfg.each do |k, v|
          if v.is_a? Hash
            _configure(v, where[k])
          else
            where[k] = v
          end
        end
      end
    end
  end
end

::Chef::Node.include ::StuartConfig::Helpers
::Chef::Recipe.include ::StuartConfig::Helpers
