#!/usr/bin/env bash

# shellcheck disable=all

IP="192.168.8.150/24"
GW="192.168.8.1"
DNS1="192.168.8.152"
DNS2="1.1.1.1"
DNS3="1.0.0.1"
BR_NOM="br0"
BR_INT="enp86s0"

# verify if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
	echo "Error: This script must be run as root."
	exit 1
fi

# delete existing bridge if it exists
del_conn() {
	if nmcli connection show "$BR_NOM" > /dev/null 2>&1; then
		nmcli connection delete "$BR_NOM"
	fi
	if nmcli connection show "$BR_INT" > /dev/null 2>&1; then
		nmcli connection delete "$BR_INT"
	fi
}

# add bridge network
add_bridge() {
	nmcli connection add type bridge ifname "$BR_NOM" \
		con-name "$BR_NOM" \
		stp no ipv4.addresses "$IP" \
		ipv4.gateway "$GW" \
		ipv4.dns "$DNS1 $DNS2 $DNS3" \
		ipv4.method manual

	nmcli connection add type bridge-slave ifname "$BR_INT" master "$BR_NOM"
	nmcli connection up "$BR_NOM"
	nmcli connection up "$BR_INT"
}

main() {
	del_conn
	add_bridge
}

main "$@"

exit 0
