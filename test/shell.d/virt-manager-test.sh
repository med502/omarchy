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

if ! rg -Fq 'sudo systemctl disable --now virtqemud.socket virtstoraged.socket virtnetworkd.socket' "$remover"; then
  fail "virt-manager stops required libvirt daemons on removal" "Expected $remover to disable virtqemud.socket, virtstoraged.socket, and virtnetworkd.socket."
fi
pass "virt-manager stops required libvirt daemons on removal"
