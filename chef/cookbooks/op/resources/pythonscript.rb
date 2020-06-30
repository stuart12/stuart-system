# Install a python script from git into local/bin

resource_name :pythonscript

action_class do
  # https://docs.chef.io/custom_resources/
  include StuartConfig::Helpers::CfgHelper
end

property :to, String, name_property: true
property :from, [Array, String, nil], default: nil

action :install do
  to = new_resource.to
  from = new_resource.from || to
  git_stuart('python-scripts')
  raw = ::File.join(git_stuart('python-scripts'), from)
  suffixed = "#{raw}.py3"
  installed = ::File.join('/usr/local/bin', to)

  link installed do
    to raw
    only_if { ::File.exist? raw }
  end

  link installed do
    to suffixed
    only_if { ::File.exist? suffixed }
  end
end
