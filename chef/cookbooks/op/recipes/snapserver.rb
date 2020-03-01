runtime_dir = 'pulse' # don't change as pidfile goes here
fifo = ::File.join('/run', runtime_dir, 'protected', 'fifo')

package 'pulseaudio' # install before configuring the unit

pa_cfg = {
  Unit: {
    '#' => 'Maintained by Chef',
    Description: 'System Pulse Audio by Chef',
    After: 'avahi-daemon.service network.target',
  },
  Service: {
    RuntimeDirectory: runtime_dir,
    PIDFile: "%t/#{runtime_dir}/pid",
    Group: 'pulse',
    ExecStartPre: "mkdir -m 1774 #{::File.dirname(fifo)}",
    ExecStart: [
      '/usr/bin/pulseaudio',
      '--daemonize=no',
      '--log-target=journal',
      '--system',
      '--disallow-module-loading',
      '--disallow-exit',
      '--high-priority',
      '--realtime',
      '--load',
      "'module-pipe-sink file=#{fifo} sink_name=Snapcast'",
    ].join(' '),
  },
  Install: {
    WantedBy: 'multi-user.target',
  },
}

systemd_unit 'pulseaudio.service' do
  content pa_cfg
  action %i[start create enable]
  notifies :restart, 'systemd_unit[pulseaudio.service]', :delayed
end

# now snapserver

execute 'reload' do
  command 'systemctl daemon-reload'
  action :nothing
end

systemd_unit 'snapserver.service' do
  action :nothing
end

cookbook_file '/etc/systemd/system/snapserver.service.d/override.conf' do
  source 'snapserver.conf'
  mode 0o644
  owner 'root'
  notifies :run, 'execute[reload]', :delayed
  notifies :restart, 'systemd_unit[snapserver.service]', :delayed
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
        stream: "pipe://#{fifo}?name=default&mode=read",
        sampleformat: '44100:16:2',
        codec: 'pcm',
      },
    },
  )
  mode 0o644
  owner 'root'
  notifies :restart, 'systemd_unit[snapserver.service]', :delayed
end

package 'snapserver' # install after setting up the configuration files
