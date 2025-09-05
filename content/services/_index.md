+++
title = 'Services'
date = 2024-01-01T08:00:00-07:00
draft = false
+++

## About

I host a few public facing services, which tend to be privacy related. 

The list of things here should grow as time goes on.

These services are open for anyone to use, but there are a few things to keep in mind: 

* These services are all logless.

* There is no way for me to prove to you that they are logless.

* As with all other hosts, I could *very* easily log IP addresses or collect more specific information at will.

* Sounds scary? **It should.** The best approach here is to self-host things, as I am doing with these for myself and choose to make them public. The only thing I can tell you is "take my word for it," similar to other "privacy focused" things such as VPN services.

* **Do not do anything with these services that can be considered illegal in Germany.** 

# SearXNG

I host a SearXNG metasearch engine instance [here](https://search.kris.sh/).

This instance of SearXNG has been slightly modified, and the source code for this fork exists [here](https://github.com/kkrruumm/searxng).

The changes have been kept minimal, so far:

* Enable favicon resolving by default
* Disable/remove a handful of engines by default due to NSFW search results from normal queries / captchas 
* Default to the black theme

This instance is not kept bleeding edge, but I do sync with upstream frequently.

# ip.kris.sh

While hardly a "service," as the footer of this website states, you may run `curl ip.kris.sh` in a terminal to quickly grab your public IP address.

If you want specifically IPv4, you may run `curl -4 ip.kris.sh` and likewise `curl -6 ip.kris.sh` for IPv6.

This is done by having Caddy respond with only `{remote_host}`.
