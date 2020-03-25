# Install a package unless it has been suppressed via an attribute

resource_name :paquet

property :package, String, name_property: true
# https://discourse.chef.io/t/can-you-access-node-attributes-from-within-a-chef-custom-resource-definition/10247/2
# FIXME: don't use stuart, how to call a helper from a Custom Resource?
property :suppressed, Hash, default: lazy { node['stuart'].dig('config', 'package', 'suppress') || {} }

action :install do
  package new_resource.package do
    not_if { new_resource.suppressed[new_resource.package] }
  end
end
