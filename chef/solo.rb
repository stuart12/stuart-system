root = File.absolute_path(File.dirname(__FILE__))

file_cache_path ::File.join('/', 'var', 'cache', 'chef')
cookbook_path ::File.join(root, 'cookbooks')
role_path ::File.join(root, 'roles')
