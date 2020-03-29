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

      def secret(which)
        secrets.dig(*which).tap do |o|
          raise("no secret #{which}") if o.nil? || o.empty?
        end
      end

      def config(*where)
        where.flatten.inject(node[BASE]['config']) { |w, k| w[k] || {} }
      end

      def git_stuart(repo)
        ::File.join(attributes(%w[git-stuart root]), repo)
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

      def self.attributes(where, cfg = {})
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
