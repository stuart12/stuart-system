return unless CfgHelper.activated? 'photo_transforms'

dir = '/etc/photo-transforms'
post_process = 'time-shadow'
transformations = [
  {
    output: '.png',
    inputs: [
      '-direct.png',
    ],
    command: [
      "/bin/sh -c 'cp \"$i0\" \"$o\"'",
    ],
  },
  {
    command: [
      'rotate-cr2',
      '--pp3 "$i1"',
      '--output "$o" "$i0"',
    ],
    output: '.jpg',
    inputs: [
      '.cr2',
      '.cr2.pp3',
    ],
  },
  {
    command: [
      'rotate-cr2',
      '--pp3 "$i1"',
      '--output "$o" "$i0"',
    ],
    output: '.jpg',
    inputs: [
      '.jpg',
      '.jpg.pp3',
    ],
  },
  {
    output: '.jpg',
    inputs: [
      '.jpg',
    ],
    command: [
      'rotate-cr2',
      '--output "$o" "$i0"',
    ],
  },
  {
    output: '.jpg',
    inputs: [
      '.cr2',
    ],
    command: [
      'rotate-cr2',
      '--output "$o" "$i0"',
    ],
  },
  {
    output: '.jpg',
    inputs: [
      '.jpg',
      '.jpg.pp3',
    ],
    command: [
      'rotate-cr2',
      '--pp3 "$i1"',
      '--output "$o" "$i0"',
    ],
  },
  {
    output: '.jpg',
    inputs: [
      '.pcd',
    ],
    command: [
      'rotate-pcd',
      '--output "$o" "$i0"',
    ],
  },
  {
    output: '.jpg',
    inputs: [
      '.png',
    ],
    command: [
      'rotate-pcd',
      '--output "$o" "$i0"',
    ],
  },
]

dft = {
  config: {
    config: {
      source: '~/photos',
      destination_directory: '~/ws/converted-photo',
      post_process: post_process,
      post_directory: '~/ws/converted-photos-post',
    },
  },
  defaults: {
    include: [
      'config.yaml',
    ],
    options: {
      # resizing_pp3: '/home/stuart/lib/RawTherapee/resize/%dx%d.pp3',
      quality: 70,
    },
    transformations: transformations,
  },
}.merge(
  {
    SVGA: {
      quality: 75,
      width: 800,
      height: 600,
    },
    HXGA: {
      quality: 93,
      width: 4096,
      height: 3072,
    },
    kiwi: {
      quality: 93,
      width: 1920,
      height: 1080,
    },
    starlite: {
      quality: 85,
      width: 2960,
      height: 1440,
    },
    dell_latitude: {
      quality: 87,
      width: 2560,
      height: 1440,
    },
  }.map do |n, o|
    [n, {
      include: [
        'defaults.yaml',
      ],
      options: o,
    }]
  end .to_h,
)
cfgs = CfgHelper.attributes(%w[photo_transforms configurations], dft)
(cfgs.dig('defaults', 'transformations') || {})
  .map { |v| v['command'].first }
  .reject { |v| v.start_with? '/' }
  .uniq
  .each do |script|
  pythonscript script
end

paquet 'python3-yaml'
paquet 'python3-exif'
pythonscript 'transform2'

directory dir do
  owner 'root'
  mode 0o755
  not_if { cfgs.empty? }
end

cfgs.each do |name, cfg|
  template ::File.join(dir, "#{name}.yaml") do
    variables(
      yaml: cfg,
    )
    mode 0o644
    owner 'root'
    source 'yaml.yaml.erb'
  end
end
