+++
title = 'Services'
date = 2024-01-01T08:00:00-07:00
draft = false
+++

## About

I host a few public facing services.

As for my game servers- all of them are run on entirely reasonable hardware for the task. I do not use irrationally overkill and expensive hardware for the sake of marketing.

# IW4x servers

At the moment, I am running several IW4x servers- known as "krummy servers."

- krummy Global Thermonuclear War:
    - `87.99.141.49:28963`

- krummy 6v6 Search and Destroy:
    - `87.99.141.49:28961`

- krummy 6v6 Team Deathmatch:
    - `87.99.141.49:28960`

- krummy Gun Game:
    - `87.99.141.49:28962`

All of these servers have the vanilla MW2 DLC maps enabled.

As of the time of writing, these servers are US-East.

# ip.kris.sh

While hardly a "service," as the footer of this website states, you may run `curl ip.kris.sh` in a terminal to quickly grab your public IP address.

If you want specifically IPv4, you may run `curl -4 ip.kris.sh` and likewise `curl -6 ip.kris.sh` for IPv6.

This is done by having Caddy respond with only `{remote_host}`.
