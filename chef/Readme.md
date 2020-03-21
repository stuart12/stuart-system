# Configure my Debian machines

## Override an attribute
Create a attribute file and use

	CfgHelper.override(
	  %w[git config sections user],
	  email: 'jill35@users.noreply.github.com',
	)

