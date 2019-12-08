root = File.absolute_path(File.dirname(__FILE__))

file_cache_path ::File.join('/', 'var', 'tmp', 'chef-cache')
cookbook_path root + '/cookbooks'
role_path root + '/roles'
