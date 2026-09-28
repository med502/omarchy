#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

installer="$ROOT/bin/omarchy-install-virt-manager"
remover="$ROOT/bin/omarchy-remove-virt-manager"

if ! rg -Fq "sudo sed -i '/env python3/ c\\#!/bin/python3' /usr/bin/virt-manager" "$installer"; then
  fail "virt-manager uses the system Python" "Expected $installer to replace virt-manager's env Python shebang."
fi
pass "virt-manager uses the system Python"

if ! rg -Fq 'sudo systemctl enable --now virtqemud.socket virtstoraged.socket' "$installer"; then
  fail "virt-manager starts required libvirt daemons" "Expected $installer to enable virtqemud.socket and virtstoraged.socket."
fi
pass "virt-manager starts required libvirt daemons"

if ! rg -Fq 'sudo systemctl disable --now virtqemud.socket virtstoraged.socket' "$remover"; then
  fail "virt-manager stops required libvirt daemons on removal" "Expected $remover to disable virtqemud.socket and virtstoraged.socket."
fi
pass "virt-manager stops required libvirt daemons on removal"
