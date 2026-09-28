#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

installer="$ROOT/bin/omarchy-install-virt-manager"
remover="$ROOT/bin/omarchy-remove-virt-manager"

if ! rg -Fq "sudo sed -i '/env python3/ c\\#!/bin/python3' /usr/bin/virt-manager" "$installer"; then
  fail "virt-manager uses the system Python" "Expected $installer to replace virt-manager's env Python shebang."
fi
pass "virt-manager uses the system Python"

if ! rg -Fq 'omarchy-pkg-add dnsmasq qemu-desktop virt-manager' "$installer"; then
  fail "virt-manager installs DNS for virtual networks" "Expected $installer to install dnsmasq."
fi
pass "virt-manager installs DNS for virtual networks"

if ! rg -Fq 'sudo systemctl enable --now virtqemud.socket virtstoraged.socket virtnetworkd.socket' "$installer"; then
  fail "virt-manager starts required libvirt daemons" "Expected $installer to enable virtqemud.socket, virtstoraged.socket, and virtnetworkd.socket."
fi
pass "virt-manager starts required libvirt daemons"

if ! rg -Fq 'sudo virsh net-autostart default' "$installer" || ! rg -Fq 'sudo virsh net-start default' "$installer"; then
  fail "virt-manager enables the default network" "Expected $installer to start and enable libvirt's default NAT network."
fi
pass "virt-manager enables the default network"

if rg -Fq 'net-start default 2>/dev/null || true' "$installer"; then
  fail "virt-manager reports network startup failures" "Expected $installer not to mask failure to start the default network."
fi
pass "virt-manager reports network startup failures"

if ! rg -Fq "sudo ufw allow in on virbr0 to any port 67 proto udp comment 'omarchy-libvirt-dhcp'" "$installer"; then
  fail "virt-manager allows DHCP from guests" "Expected $installer to allow DHCP requests on virbr0."
fi
pass "virt-manager allows DHCP from guests"

if ! rg -Fq "sudo ufw allow in on virbr0 to any port 53 proto udp comment 'omarchy-libvirt-dns'" "$installer" || ! rg -Fq "sudo ufw allow in on virbr0 to any port 53 proto tcp comment 'omarchy-libvirt-dns'" "$installer"; then
  fail "virt-manager allows DNS from guests" "Expected $installer to allow TCP and UDP DNS requests on virbr0."
fi
pass "virt-manager allows DNS from guests"

if ! rg -Fq 'sudo systemctl disable --now virtqemud.socket virtstoraged.socket virtnetworkd.socket' "$remover"; then
  fail "virt-manager stops required libvirt daemons on removal" "Expected $remover to disable virtqemud.socket, virtstoraged.socket, and virtnetworkd.socket."
fi
pass "virt-manager stops required libvirt daemons on removal"

if ! rg -Fq 'sudo ufw --force delete allow in on virbr0 to any port 67 proto udp' "$remover"; then
  fail "virt-manager removes its DHCP firewall rule" "Expected $remover to remove the DHCP rule for virbr0."
fi
pass "virt-manager removes its DHCP firewall rule"
