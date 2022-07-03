#!/bin/bash

# Prepare run dir
if [ ! -d "/var/run/sshd" ]; then
  mkdir -p /var/run/sshd
fi

set -m

# Install routes
IFS=',' read -ra SUBNETS <<< "${ADVERTISE_ROUTES}"
for s in "${SUBNETS[@]}"; do
  ip route add "$s" via "${CONTAINER_GATEWAY}"
done

# Start tailscaled and bring tailscale up 
/usr/local/bin/tailscaled --tun=userspace-networking &
until /usr/local/bin/tailscale up \
	--authkey=${AUTH_KEY} \
	--advertise-routes="${ADVERTISE_ROUTES}" \
	--login-server="${LOGIN_SERVER}" \
	--accept-routes=true \
	--accept-dns=false
do
    sleep 0.1
done
echo Tailscale started

# Start SSH
/usr/sbin/sshd -D

fg %1
