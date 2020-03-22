resource_name :append

property :path, String, name_property: true
property :line, String
property :owner, String, default: 'root'
property :group, String, default: 'root'
property :mode, Integer, default: 0o644

action :update do
  current = IO.read(new_resource.path)
  line = "#{new_resource.line}\n"
  file new_resource.path do
    content current + line
    owner new_resource.owner
    group new_resource.group
    mode new_resource.mode
    not_if { current.include?("\n#{line}") || current.start_with?(line) }
  end
end
