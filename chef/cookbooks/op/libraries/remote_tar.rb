# https://mearnsb.medium.com/attributes-are-dead-long-live-helper-libraries-e936513793cc

# variable to remote_tar resource and users of the resource
class RemoteTar
  def initialize(node)
    @node = node
  end

  def where
    '/opt'
  end

  def sub_directory
    'versions'
  end

  def bin
    '/usr/local/bin'
  end
end

# Update the Chef::Resource and Chef::Recipe classes to make our helper available in recipes and resources.
class Chef
  # so can be usde in resource files
  class Resource
    def remote_tar_lib
      RemoteTar.new(node)
    end
  end
  # so can be usde in recipes
  class Recipe
    def remote_tar_lib
      RemoteTar.new(node)
    end
  end
end
