#!/bin/sh
# Managed by Chef
# echo $0 $reason add "$INTERNAL_IP4_ADDRESS/$INTERNAL_IP4_NETMASKLEN" dev "$TUNDEV"
case "$reason" in
connect)
	exec ip address add "$INTERNAL_IP4_ADDRESS/$INTERNAL_IP4_NETMASKLEN" dev "$TUNDEV"
	;;
esac
