# map xev names to keycode
class KeyCodes
  @mapping = nil
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

  def self.keypad(key)
    keycode("KP#{key}")
  end

  def self.keycode(key)
    mapping[key.to_s.upcase]
  end
end

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

      def config
        node[BASE]['config']
      end

      def add_package(name)
        node.default[BASE]['config']['packages']['install'][name] = true
      end

      def systemd_unit(name, content)
        node.default[BASE]['config']['systemd']['units'][name]['content'] = content
      end

      def activated?(name)
        node[BASE].dig('config', name, 'activate')
      end

      def network
        networking = config['networking'] || {}
        gateway = networking['gateway']
        mask = networking['mask']
        return nil unless gateway && mask
        IPAddr.new("#{gateway}/#{mask}")
      end
    end
  end
end

::Chef::Node.send(:include, ::StuartConfig::Helpers)
::Chef::Recipe.send(:include, ::StuartConfig::Helpers)
