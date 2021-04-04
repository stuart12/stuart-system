#https://github.com/chef/chef/blob/master/lib/chef/resource/sudo.rb
#
resource_name :sudo

property :filename, String,
  name_property: true,
  coerce: proc { |x| x.gsub(/[\.~]/, "__") }

property :users, [String, Array],
  default: [],
  coerce: proc { |x| x.is_a?(Array) ? x : x.split(/\s*,\s*/) }

property :groups, [String, Array],
  default: [],
  coerce: proc { |x| coerce_groups(x) }

property :commands, Array,
  default: ["ALL"]

property :host, String,
  default: "ALL"

property :runas, String,
  default: "ALL"

property :nopasswd, [TrueClass, FalseClass],
  default: false

property :noexec, [TrueClass, FalseClass],
  default: false

property :variables, [Hash, nil],
  default: nil

property :defaults, Array,
  default: []

property :command_aliases, Array,
  default: []

property :setenv, [TrueClass, FalseClass],
  default: false

property :env_keep_add, Array,
  default: []

property :env_keep_subtract, Array,
  default: []

property :visudo_path, String,
  deprecated: true

property :visudo_binary, String,
  default: "/usr/sbin/visudo"

property :config_prefix, String,
  default: lazy { platform_config_prefix }

# handle legacy cookbook property
def after_created
  raise "The 'visudo_path' property from the sudo cookbook has been replaced with the 'visudo_binary' property. The path is now more intelligently determined and for most users specifying the path should no longer be necessary. If this resource still cannot determine the path to visudo then provide the absolute path to the binary with the 'visudo_binary' property." if visudo_path
end

# VERY old legacy properties
alias_method :user, :users
alias_method :group, :groups

# make sure each group starts with a %
def coerce_groups(x)
  # split strings on the commas with optional spaces on either side
  groups = x.is_a?(Array) ? x : x.split(/\s*,\s*/)

  # make sure all the groups start with %
  groups.map { |g| g[0] == "%" ? g : "%#{g}" }
end

# default config prefix paths based on platform
# @return [String]
def platform_config_prefix
  case node["platform_family"]
  when "smartos"
    "/opt/local/etc"
  when "mac_os_x"
    "/private/etc"
  when "freebsd"
    "/usr/local/etc"
  else
    "/etc"
  end
end

action :create do
  description "Create a single sudoers config in the sudoers.d directory"

  validate_properties

  if docker? # don't even put this into resource collection unless we're in docker
    package "sudo" do
      not_if "which sudo"
    end
  end

  target = "#{new_resource.config_prefix}/sudoers.d/"
  directory(target)

  Chef::Log.warn("#{new_resource.filename} will be rendered, but will not take effect because the #{new_resource.config_prefix}/sudoers config lacks the includedir directive that loads configs from #{new_resource.config_prefix}/sudoers.d/!") if ::File.readlines("#{new_resource.config_prefix}/sudoers").grep(/includedir/).empty?
  file_path = "#{target}#{new_resource.filename}"

  template file_path do
    source ::File.expand_path("../templates/default/sudoer.erb", __dir__)
    #source 'sudoer.erb'
    local true
    mode "0440"
    variables sudoer:            (new_resource.groups + new_resource.users).join(","),
              host:               new_resource.host,
              runas:              new_resource.runas,
              nopasswd:           new_resource.nopasswd,
              noexec:             new_resource.noexec,
              commands:           new_resource.commands,
              command_aliases:    new_resource.command_aliases,
              defaults:           new_resource.defaults,
              setenv:             new_resource.setenv,
              env_keep_add:       new_resource.env_keep_add,
              env_keep_subtract:  new_resource.env_keep_subtract
    verify visudo_content(file_path) if visudo_present?
    action :create
  end
end

action :install do
  Chef::Log.warn("The sudo :install action has been renamed :create. Please update your cookbook code for the new action")
  action_create
end

action :remove do
  Chef::Log.warn("The sudo :remove action has been renamed :delete. Please update your cookbook code for the new action")
  action_delete
end

# Removes a user from the sudoers group
action :delete do
  description "Remove a sudoers config from the sudoers.d directory"

  file "#{new_resource.config_prefix}/sudoers.d/#{new_resource.filename}" do
    action :delete
  end
end

action_class do
  # Ensure that the inputs are valid (we cannot just use the resource for this)
  def validate_properties
    # if group, user, env_keep_add, env_keep_subtract and template are nil, throw an exception
    raise "You must specify users, groups, env_keep_add, env_keep_subtract, or template properties!" if new_resource.users.empty? && new_resource.groups.empty? && new_resource.env_keep_add.empty? && new_resource.env_keep_subtract.empty?
  end

  def visudo_present?
    return true if ::File.exist?(new_resource.visudo_binary)

    Chef::Log.warn("The visudo binary cannot be found at '#{new_resource.visudo_binary}'. Skipping sudoer file validation. If visudo is on this system you can specify the path using the 'visudo_binary' property.")
  end

  def visudo_content(path)
    if ::File.exist?(path)
      "cat #{new_resource.config_prefix}/sudoers | #{new_resource.visudo_binary} -cf - && #{new_resource.visudo_binary} -cf %{path}"
    else
      "cat #{new_resource.config_prefix}/sudoers %{path} | #{new_resource.visudo_binary} -cf -"
    end
  end
end
