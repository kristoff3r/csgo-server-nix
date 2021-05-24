#!/bin/sh

set -e

NIXPKGS_ALLOW_UNFREE=1 nix-build '<nixpkgs/nixos>' -A vm --arg configuration ./configuration.nix
rm -f nixos.qcow2 && result/bin/run-nixos-vm
