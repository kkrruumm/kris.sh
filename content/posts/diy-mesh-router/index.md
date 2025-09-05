---
title: "DIY Mesh Router"
date: 2024-02-16T20:51:42-06:00
draft: false
tags: ['Linux', 'Networking']
---

A while back, I wrote a script to set up a WiFi to Ethernet bridge device, and I have been using this for my connection at home for a while now. In this post, I will be describing the process of manually setting this up.

If you just want to get your network up without reading further or performing a manual setup, the script can be found on my GitHub [here](https://github.com/kkrruumm/wireless-eth-bridge).

I purchased a Dell Optiplex 3040 Micro for ~$100 USD on eBay a bit ago specifically for this purpose due to its awesome WiFi antenna, and have been using this to provide my devices with a connection for roughly a week as of the time of writing.

For the price, this machine wasn't a bad buy (aside from the UEFI implementation being worse than MSIs) with an i5 6500t, 8gb of 1600mhz DDR3, and a 256gb TeamGroup Vulcan Z SSD that magically only had 1 power on hour and 27 power cycles according to S.M.A.R.T data. This machine is completely inaudible, even when under load.

Now, I'm sure you're thinking "Why didn't you just run an Ethernet cable or use MOCA?" 

Well, I do not have Coaxial cables ran for MOCA, and I did not want to run an Ethernet cable up my stairs or drill a hole in the ceiling to route the cable through, nor did I want to get WiFi cards for each of my machines as I would prefer to keep my LAN transfers on Ethernet, so this machine connected to a switch is a good solution.

# Necessary software

To achieve this setup, we will be using nftables for our NAT (Network Address Translation), dnsmasq for our DHCP server to provide devices with IP addresses, and iproute or ifupdown to configure our interfaces. 

ifupdown is really preferred here, as with iproute we will be creating services to run our commands, while ifupdown is an actual process rather than just a CLI tool. However, some Linux distributions do not use or package ifupdown.

Regardless of the Linux distribution you choose to use here, they should have nftables and dnsmasq packaged. For iproute or ifupdown, consult your distributions documentation and choose the appropriate one.

In my case, I will be using Alpine Linux which uses ifupdown.

# ifupdown setup

**Note:** If your distribution does not package ifupdown, you should skip to the iproute setup section instead of following ifupdown instructions.

The goal is to assign a static IP address to this interface, as the IP address of this interface should not be changing.

To set up ifupdown, the following needs to be added to ``/etc/network/interfaces``:

```sh
auto <ethernet-interface> 
allow-hotplug <ethernet-interface>
iface <ethernet-interface> inet static
    address <ethernet-interface-ip> 
    gateway <ethernet-interface-ip>
```

``<ethernet-interface>`` in the ``auto``, ``allow-hotplug``, and ``iface`` lines should be replaced with the ethernet interface you intend to use for connecting other devices you'd like to provide with internet, such as ``eth0``.

``<ethernet-interface-ip>`` in the ``address`` line should be replaced with the IP address you want to give this interface, I typically put ``10.0.1.1/24`` here because I use ``10.0.0.X`` on my normal networks.
``/24`` here specifies the subnet mask via CIDR notation.

``<ethernet-interface-ip>`` in the ``gateway`` line should specify the gateway, you can enter the same value as the ``address`` line, so ``10.0.1.1/24`` for this example.

Once you've done this, your Ethernet interface has been fully configured and you can continue to the nftables setup.

# iproute setup

**Note:** If your distribution packages ifupdown, you should go back to the ifupdown section instead of using iproute commands.

Unlike ifupdown, iproute is just a CLI tool to configure an interface.

In order to achieve what we're trying to do here, it's necessary to have these commands run on every boot, so the most straightforward option is to use SystemD/OpenRC services.

The goal is to assign a static IP address to this interface, as the IP address of this interface should not be changing.

**OpenRC:**

Create a file in ``/etc/init.d`` to be your service, you can name this anything you want to, however I will call mine "wirelessebridge"

Contents of ``/etc/init.d/wirelessebridge``:

```sh
#!/sbin/openrc-run
command="ip addr add <ethernet-interface-ip> dev <ethernet-interface> && \
ip link set <ethernet-interface> up && \
rc-service dnsmasq restart" 
```

**SystemD:**

Create a file in ``/etc/systemd/system`` to be your service, you can name this anything you want to, however I will call mine "wirelessebridge.service"

Contents of ``/etc/systemd/system/wirelessebridge.service``:

```sh
Description=Configure wireless eth bridge interface
        
[Service]
Type=oneshot
ExecStart=/bin/sh -c "ip addr add <ethernet-interface-ip> dev <ethernet-interface> && \
ip link set <ethernet-interface> up && \
systemctl restart dnsmasq"
        
[Install]
WantedBy=multi-user.target
```

For both of these setups, ``<ethernet-interface>`` should be replaced with the Ethernet interface you intend to use for connecting other devices you'd like to provide with internet, such as ``eth0``.

``<ethernet-interface-ip>`` should be replaced with the IP address you want to give this interface, I typically put ``10.0.1.1/24`` here because I use ``10.0.0.X`` on my normal networks.
``/24`` here specifies the subnet mask via CIDR notation.

Once you've set this up for the init system you are using, your Ethernet interface has been fully configured and you can continue to the nftables setup.

# nftables setup

After you have set up ifupdown **OR** iproute services, it's time to begin setting up our NAT with nftables.

The role of NAT (Network Address Translation) is at the core of how this functions, as NAT provides us with a way to route traffic to another IP address, such as from our wireless interface to our Ethernet interface.

To get started, we need to create a NAT table with:

``nft add table ip nat``, the type ``ip`` here does specify IPv4 addresses.

Once we've created our table to store our chains, it's time to create the postrouting chain in the NAT table with:

``nft add chain ip nat postrouting '{type nat hook postrouting priority 100; policy accept;}'``

Postrouting allows us to alter packets after they have exited the output chain.

Next, we need to add a rule to our postrouting chain with:

``nft add rule ip nat postrouting oifname <wireless-interface> masquerade``

``<wireless-interface>`` here should be replaced with the name of the wireless interface on the system, such as wlan0.

``oifname`` here specifies the *output interface.*

``masquerade`` is a Linux networking concept that allows us to translate an IP address (or multiple IP addresses) to a different single IP address.

If you have a ``filter`` table in your nftables config, you need to allow forwarding via:

``nft add chain inet filter forward '{type filter hook forward priority 0; policy accept;}'``

You should also allow input from the Ethernet interface:

``nft add rule inet filter input iifname <ethernet-interface> accept``

Similar to ``oifname`` for the wireless interface, ``iifname`` here specifies the *input interface.*

After you've completed these steps, do save your nftables config via: 

``nft list ruleset > /etc/nftables.conf`` or potentially ``nft list ruleset > /etc/nftables.nft``, depending on where this config should exist for your distro of choice. On Alpine Linux, this file exists at ``/etc/nftables.nft``.

# Enabling IPv4 forwarding

Enabling IPv4 forwarding should be the same process on all Linux distros, just adding a line to the ``/etc/sysctl.conf`` file with:

``echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf``

If this line already exists in this file, uncomment it instead of adding a new line.

# dnsmasq setup

Finally, we need to set up dnsmasq for our DHCP server.

Add the following contents to ``/etc/dnsmasq.d/ethbridge.conf``:

```sh
interface=<ethernet-interface>
bind-interfaces
server=<dns-server>
domain-needed
bogus-priv
dhcp-range=<dhcp-range>
```

Replace ``<ethernet-interface>`` here with the name of the same Ethernet interface we specified earlier, such as ``eth0``. 

Replace ``<dns-server>`` here with the IP address of your preferred upstream DNS server, since I prefer Quad9, I use ``9.9.9.9`` for this value.

Replace ``<dhcp-range>`` with your desired range of IP addresses and their lease time, since I use ``10.0.1.X`` addresses for this, I will use ``10.0.1.2,10.0.1.254,24h`` for this value. This specifies a range of ``10.0.1.2`` through ``10.0.1.254`` with a lease time of 24 hours, starting at ``10.0.1.2`` because ``10.0.1.1`` belongs to the Ethernet interface on this device.

``bind-interfaces`` here tells dnsmasq to bind only the interfaces it is listening on, instead of binding the wildcard address. 

``domain-needed`` here tells dnsmasq to never forward plain names. (Names without a dot or domain part) 

``bogus-priv`` here tells dnsmasq to never forward addresses in the non-routed address spaces.

According to the dnsmasq example config file, the last two options (``domain-needed`` and ``bogus-priv``) filter out queries which the public DNS cannot answer, and which load the servers unnecessarily.

Once you have completed this, assuming you've also completed your nftables and ifupdown or iproute setup, you should be able to reboot this machine and get an IP address and internet from the Ethernet port on this device! (Assuming it's connected to WiFi.)

# Closing thoughts

While this is a somewhat lengthy process to complete manually, my goal here was to explain a bit about the technology that goes into a setup like this. However, if you just went for the script to set this up automatically, that's still awesome!

If you found this script or blogpost useful, I would appreciate a star on the Github repository for this script!
