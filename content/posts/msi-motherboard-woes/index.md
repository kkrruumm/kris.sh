---
title: "MSI Motherboard Woes"
date: 2024-02-04T14:59:53-06:00
draft: false
tags: ['Linux', 'UEFI']
---
I just can't get enough UEFI, huh?

# Introduction

I have had my fair share of problems related to MSI motherboards, and I thought it may be reasonable to briefly talk about some of these issues and provide the workarounds I've discovered for them.

# UEFI Standards Compliance

Unfortunately, we live in a world where not all UEFI implementations are ideal or correct.

According to the [UEFI specifications](https://uefi.org/specs/UEFI/2.10/03_Boot_Manager.html#boot-manager-programming), `"The firmware should not, under normal operation, automatically remove any correctly formed Boot#### variable currently referenced by the BootOrder or BootNext variables. Such removal should be limited to scenarios where the firmware is guided by direct user interaction."`

It seems to be a trend with MSI motherboards to directly violate this. This issue can be discovered when one chooses to pursue a somewhat abnormal setup, such as booting from a UKI (Unified Kernel Image) or by using efistub, but also with run-of-the-mill setups when installing GRUB normally via the `grub-install` command.

After running `grub-install`, or using `efibootmgr` to create the boot entry, it's possible to list the current boot entries by running `efibootmgr` without any additional arguments. There, the boot entry should be visible until you reboot. Once rebooted, you may notice that you've not booted into your freshly installed Linux distribution at all, and after booting back into the live Linux system to investigate, running `efibootmgr` shows your boot entry has magically gone missing.

So what now?

If you're using the GRUB bootloader, this problem can be worked around by adding the `--removable` flag to your `grub-install` command.

Otherwise, if you don't want to do that OR are running without a bootloader for an efistub or a UKI setup, it's possible to create an empty file in the expected location to kind of trick the motherboard into not removing your boot entries.

I have achieved this by running `mkdir -p /boot/EFI/BOOT` and then just creating an empty file there with `touch /boot/EFI/BOOT/BOOTX64.EFI`, which should work for basically all boot setups.

This behavior has been observed on both my MSI Z490 MAG TOMAHAWK as well as a friend's MSI MPG Z690 EDGE WIFI DDR5.

Do note that if you're using Secure Boot, you'll want to change the boot order on your system so you don't receive a Secure Boot violation when you attempt to boot your system because this empty file isn't signed.

# Not-so-Secure Boot

By default, a **ton** of MSI motherboards have extremely insecure Secure Boot defaults, and my Z490 MAG TOMAHAWK is no exception.

Tucked away in a submenu of the Secure Boot menu that may not be immediately obvious, there's another section called "Image Execution Policy" that determines how it will handle Secure Boot violations, and on a lot of boards, the default is "Always Execute."

"Always Execute" here is an absolutely terrible default, given that if a user were to enable Secure Boot and not check this menu, they will have enabled a feature that does exactly nothing due to it always executing on violation.

Documentation of this behavior and a list of impacted motherboards exists on [sbctl's issue tracker](https://github.com/Foxboron/sbctl/issues/181).

To solve this issue, if you're using secure boot, do change the "Removable Media" and "Fixed Media" options to "Deny Execute"

**Absolutely do not set these to "Always Deny" unless you are aware of what you're doing.**

Changing Option ROM to "Deny Execute" can also be a little bit touchy, do be careful if you choose to do so.

Of course, having a security setting that doesn't do what it claims to do by default is worse than just not having said security feature.

There are quite a few other security issues with MSI motherboards that have been well explained on [Dawid Potocki's blog](https://dawidpotocki.com/en/2023/02/26/msi-insecure-boot-part-2/#msis-other-security-issues), so I won't go into those here.

# Closing thoughts

It is quite unfortunate that these issues exist, given that MSI motherboards have some of the best hardware and they tend to be quite reliable.

Hopefully these issues will be solved at some point in the future.
