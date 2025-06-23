#!/usr/bin/env bash

if [ ! -f /etc/secrets/tailscale ]; then
  # Already ran once, so skip now, but treat it as okay
  exit 0
fi

tailscale up --ssh --auth-key="$(cat /etc/secrets/tailscale)"
rm /etc/secrets/tailscale

sed -i "s/XXX/$(cat /etc/secrets/consul)/d" /etc/consul/consul.d/server.hcl
