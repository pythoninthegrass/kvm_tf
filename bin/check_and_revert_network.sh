#!/usr/bin/env bash

# shellcheck disable=all

IP="192.168.8.150/24"
GW="192.168.8.1"
DNS1="192.168.8.152"
DNS2="1.1.1.1"
DNS3="1.0.0.1"
BR_NOM="br0"
BR_INT="enp86s0"
FALLBACK_CONN="Fallback_enp86s0"
TTL=2

# verify if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
	echo "Error: This script must be run as root."
	exit 1
fi

check_network() {
	ping -c 4 8.8.8.8 > /dev/null 2>&1
	return $?
}

create_fallback_connection() {
	nmcli connection add type ethernet con-name "$FALLBACK_CONN" ifname "$BR_INT" \
		ipv4.addresses "$IP" \
		ipv4.gateway "$GW" \
		ipv4.dns "$DNS1 $DNS2 $DNS3" \
		ipv4.method manual
}

revert_connection() {
	nmcli connection down "$BR_NOM"
	nmcli connection delete "$BR_NOM"
	nmcli connection delete "$BR_INT"
	if ! nmcli connection show "$FALLBACK_CONN" > /dev/null 2>&1; then
		create_fallback_connection
	fi
	nmcli connection up "$FALLBACK_CONN"
}

setup_systemd_timer() {
	cat <<- EOF > /etc/systemd/system/network-check.service
		[Unit]
		Description=Check network and revert if necessary

		[Service]
		ExecStart=/usr/local/bin/check_and_revert_network.sh
		Type=oneshot
	EOF

	cat <<- EOF > /etc/systemd/system/network-check.timer
		[Unit]
		Description=Run network check periodically

		[Timer]
		OnBootSec=${TTL}min
		OnUnitActiveSec=${TTL}min

		[Install]
		WantedBy=timers.target
	EOF

	systemctl daemon-reload
	systemctl enable network-check.timer
	systemctl start network-check.timer
}

if [ "$1" = "--install" ]; then
	# Copy this script to /usr/local/bin
	cp "$0" /usr/local/bin/check_and_revert_network.sh

	# Create fallback connection
	create_fallback_connection

	# Setup systemd timer
	setup_systemd_timer
	echo -e "Installation complete. The network check will run every $TTL minutes."
	exit 0
fi

if ! check_network; then
	revert_connection
fi
