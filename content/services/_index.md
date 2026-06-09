+++
title = 'Services'
date = 2024-01-01T08:00:00-07:00
draft = false
+++

## About

To be filled out, at some point.

# ip.kris.sh

While hardly a "service," as the footer of this website states, you may run `curl ip.kris.sh` in a terminal to quickly grab your public IP address.

If you want specifically IPv4, you may run `curl -4 ip.kris.sh` and likewise `curl -6 ip.kris.sh` for IPv6.

This is done by having Caddy respond with only `{remote_host}`.
