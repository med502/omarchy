#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

installer="$ROOT/bin/omarchy-install-virt-manager"
remover="$ROOT/bin/omarchy-remove-virt-manager"
python_hook="$ROOT/default/libalpm/hooks/50-omarchy-virt-manager-python.hook"

if ! rg -Fq 'Target = virt-manager' "$python_hook" || ! rg -Fq 'Operation = Upgrade' "$python_hook" || ! rg -Fq "Exec = /usr/bin/sed -i '/env python3/ c\\#!/bin/python3' /usr/bin/virt-manager" "$python_hook"; then
  fail "virt-manager uses the system Python after upgrades" "Expected $python_hook to restore virt-manager's system Python shebang after package upgrades."
fi
pass "virt-manager uses the system Python after upgrades"

if ! rg -Fxq 'set -e' "$installer"; then
  fail "virt-manager stops after setup failures" "Expected $installer to stop when a required setup command fails."
fi
pass "virt-manager stops after setup failures"

if ! rg -Fq 'if ! omarchy-pkg-add dnsmasq qemu-desktop virt-manager; then' "$installer"; then
  fail "virt-manager aborts when package installation fails" "Expected $installer to abort if required packages cannot be installed."
fi
pass "virt-manager aborts when package installation fails"

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

if ! rg -Fq "sudo ufw route allow in on virbr0 comment 'omarchy-libvirt-forward'" "$installer"; then
  fail "virt-manager allows guest internet access" "Expected $installer to allow forwarded traffic from virbr0."
fi
pass "virt-manager allows guest internet access"

if rg -Fq 'systemctl disable --now virtqemud.socket virtstoraged.socket virtnetworkd.socket' "$remover"; then
  fail "virt-manager preserves shared libvirt sockets" "Expected $remover not to disable sockets that other VM clients may use."
fi
pass "virt-manager preserves shared libvirt sockets"

if ! rg -Fq 'if ! omarchy-pkg-drop dnsmasq virt-manager qemu-desktop; then' "$remover"; then
  fail "virt-manager reports package removal failures" "Expected $remover to stop if its packages cannot be removed."
fi
pass "virt-manager reports package removal failures"

if ! rg -Fq 'sudo ufw --force delete allow in on virbr0 to any port 67 proto udp' "$remover"; then
  fail "virt-manager removes its DHCP firewall rule" "Expected $remover to remove the DHCP rule for virbr0."
fi
pass "virt-manager removes its DHCP firewall rule"

if ! rg -Fq 'sudo ufw --force delete route allow in on virbr0' "$remover"; then
  fail "virt-manager removes its forwarding firewall rule" "Expected $remover to remove the forwarding rule for virbr0."
fi
pass "virt-manager removes its forwarding firewall rule"
