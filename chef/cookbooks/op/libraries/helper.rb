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
