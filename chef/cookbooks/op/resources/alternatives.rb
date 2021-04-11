resource_name :alternatives

property :link_name, String, name_property: true
property :path, String
property :link, String,
         default: lazy { |n| "/usr/bin/#{n.link_name}" },
         description: 'The path to the alternatives link.'

# https://github.com/chef/chef/blob/91a14d0333d14c3ee8956a71fac765e89944cc99/lib/chef/resource/alternatives.rb
#
action :set do
  if current_path != new_resource.path
    converge_by("setting alternative #{new_resource.link_name} #{new_resource.path}") do
      output = shell_out(alternatives_cmd, '--set', new_resource.link_name, new_resource.path)
      unless output.zero?
        raise "failed to set alternative #{new_resource.link_name} #{new_resource.path} \n #{output.stdout.strip}"
      end
    end
  end
end

action_class do
  def alternatives_cmd
    'update-alternatives'
  end

  def current_path
    match = shell_out(alternatives_cmd, '--display', new_resource.link_name).stdout.match(/link currently points to (.*)/)
    match[1]
  end
end
