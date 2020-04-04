# Install a package unless it has been suppressed via an attribute

resource_name :paquet

property :pkg_name, String, name_property: true
# https://discourse.chef.io/t/can-you-access-node-attributes-from-within-a-chef-custom-resource-definition/10247/2
# FIXME: don't use stuart, how to call a helper from a Custom Resource?
property :suppressed, Hash, default: lazy { node['stuart'].dig('config', 'package', 'suppress') || {} }

action :install do
  package new_resource.pkg_name do
    not_if { new_resource.suppressed[new_resource.pkg_name] }
  end
end
