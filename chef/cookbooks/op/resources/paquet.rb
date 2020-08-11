# Install a package or its possible replacement

resource_name :paquet

action_class do
  # https://docs.chef.io/custom_resources/
  include StuartConfig::Helpers::CfgHelper
end

property :pkg_name, String, name_property: true

action :install do
  replacement = config(%w[package replace])[new_resource.pkg_name]

  if replacement.nil? || replacement
    package replacement || new_resource.pkg_name do
      action :install
    end
  end
end
