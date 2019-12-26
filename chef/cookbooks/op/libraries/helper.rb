# https://medium.com/@mearns.b/attributes-are-dead-long-live-helper-libraries-e936513793cc
# A helper class for encapsulating information about the installation and configuration of the app.
class CfgHelper
  def initialize(node)
    @node = node
  end

  def app_name
    'MyHelper'
  end

  def config
    @node['stuart']['config']
  end

  def network
    networking = config['networking'] || {}
    gateway = networking['gateway']
    mask = networking['mask']
    return nil unless gateway && mask
    IPAddr.new("#{gateway}/#{mask}")
  end
end

# Update the Chef::Resource and Chef::Recipe classes to make our helper available in recipes and resources.
class Chef
  # Open Resource
  class Resource
    def cfg_helper
      CfgHelper.new(node)
    end
  end
  # Open Recipe
  class Recipe
    def cfg_helper
      CfgHelper.new(node)
    end
  end
end
