resource_name :remote_deb

action_class do
  include StuartConfig::Helpers::CfgHelper # https://docs.chef.io/custom_resources/
end

property :name, String, name_property: true
property :url, String
property :checksum, String
property :options, [String, Array], default: []
property :dependencies, Array, default: []
property :hide, [String, Array], default: []
property :delete, [String, Array], default: []

action :manage do
  new_resource.dependencies.each do |pkg|
    paquet pkg
  end

  deb = ::File.join(Chef::Config[:file_cache_path], "#{new_resource.name}.deb")

  remote_file deb do
    source new_resource.url
    checksum new_resource.checksum
    owner 'root'
    mode 0o644
    notifies :remove, "dpkg_package[#{new_resource.name}]", :immediately
  end

  dpkg_package new_resource.name do
    source deb
    options [new_resource.options].flatten + ['--no-triggers']
  end

  group = config(%w[work group])
  [new_resource.hide].flatten.each do |fname|
    directory fname do
      group group
      mode 0o754
    end
  end

  [new_resource.delete].flatten.each do |fname|
    file fname do
      action :delete
    end
  end
end
