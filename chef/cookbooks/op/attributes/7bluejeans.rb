return unless CfgHelper.activated? 'bluejeans'

CfgHelper.attributes(
  %w[users users],
  bluejeans: {
    name: 'Blue Jeans',
    groups: ['video'],
  },
)
