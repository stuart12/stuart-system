execute 'reload' do
  command 'systemctl daemon-reload'
  action :nothing
end

systemd_unit 'snapserver' do
  action :nothing
end

cookbook_file '/etc/systemd/system/snapserver.service.d/override.conf' do
  source 'snapserver.conf'
  mode 0o644
  owner 'root'
  notifies :run, 'execute[reload]', :delayed
  notifies :restart, 'systemd_unit[snapserver]', :delayed
end

directory '/etc/cheffise' do
  mode 0o755
  owner 'root'
end

template '/etc/cheffise/snapserver.conf' do
  source 'ini.erb'
  variables(
    sections: {
      stream: {
        stream: 'pipe:///run/pulse/fifo?name=default&mode=read',
        sampleformat: '44100:16:2',
        codec: 'pcm',
      },
    },
  )
  mode 0o644
  owner 'root'
  notifies :restart, 'systemd_unit[snapserver]', :delayed
end

package 'snapserver'
