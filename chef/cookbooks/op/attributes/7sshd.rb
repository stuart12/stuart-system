ck = 'stuart'

return unless node[ck].dig('config', 'sshd', 'activate')

default[ck]['config']['sshd']['config'] =
  {
    ListenAddress: '0.0.0.0',
    PasswordAuthentication: false,
    ChallengeResponseAuthentication: false,
    UsePAM: true,
    X11Forwarding: true,
    PrintMotd: false,
    AcceptEnv: %w[LANG LC_*],
    Subsystem: %w[sftp /usr/lib/openssh/sftp-server],
  }

default[ck]['config']['packages']['install']['openssh-server'] = true
