# Inspired by:
#
#   * https://nixos.mayflower.consulting/blog/2018/09/11/custom-images/
#   * http://blog.patapon.info/nixos-local-vm/#accessing-the-vm-with-ssh
#
# Build VM using:
#
#     NIX_PATH=.. nix-build '<nixpkgs/nixos>' -A vm --arg configuration ./configuration.nix
#
# The `./` is important, as it needs to be a nix path literal.
# Run VM using:
#
#     rm -f nixos.qcow2 && result/bin/run-nixos-vm
#
# Depending on your permissions you may have to use `sudo` for running.
# A QEMU window will pop up and you can log in as `root` with empty password.
#
# Even better, with SSH:
#
#     rm -f nixos.qcow2 && env QEMU_NET_OPTS=hostfwd=tcp::2221-:22
#
# Then you can ssh in using:
#
#     ssh -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no root@localhost -p 2221
#
# Note by default `ping` will not work, but other Internet stuff will, see
# https://wiki.qemu.org/Documentation/Networking#User_Networking_.28SLIRP.29
#
# Note that running `nixos-rebuild` in the VM may do a lot of downloads,
# even though the files it downloads are apparently already present
# in the nix store, see:
#     https://discourse.nixos.org/t/how-to-build-a-nixos-vm-with-nix-in-which-nixos-rebuild-is-a-no-op/7937

{ pkgs, lib, config, ... }:

with lib;
let
  mount_guest_path = "/root/host";
  mount_host_path = toString ./guest;
  mount_tag = "hostdir";
  csgo-plugins = (pkgs.callPackage ../. {}).plugins;
in
{
  imports = [
    <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
    <nixpkgs/nixos/modules/virtualisation/qemu-vm.nix>
    ../nixos
  ];

  config = {
    services.qemuGuest.enable = true;

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      autoResize = true;
    };

    boot = {
      growPartition = true;
      kernelParams = [ "console=ttyS0 boot.shell_on_fail" ];
      loader.timeout = 5;
      # Not set because `qemu-vm.nix` overrides it anyway:
      # loader.grub.device = "/dev/vda";

      # Mount nixpkgs submodule at `/root/nixpkgs` in guest.
      initrd.postMountCommands = ''
        mkdir -p "$targetRoot/${mount_guest_path}"
        mount -t 9p "${mount_tag}" "$targetRoot/${mount_guest_path}" -o trans=virtio,version=9p2000.L,cache=none
      '';

      # This is the functionality we want to test.
      # From inside the VM, you can run:
      #     cd host-dir
      #     NIX_PATH=.:nixos-config=$PWD/grub-test-vm/configuration.nix nixos-rebuild switch --install-bootloader --fast
      loader.grub.extraGrubInstallArgs = [
        # Uncomment to try this change:
        # "--modules=nativedisk ahci pata part_gpt part_msdos diskfilter mdraid1x lvm ext2"
      ];

      # Copy VM configuration into guest so that we can use `nixos-rebuild` in there.
      postBootCommands = ''
        cp ${./configuration.nix} /etc/nixos/configuration.nix
      '';
    };

    virtualisation = {
      diskSize = 40000; # MB
      memorySize = 2048; # MB
      qemu.options = [
        "-virtfs local,path=${mount_host_path},security_model=none,mount_tag=${mount_tag}"
      ];

      # We don't want to use tmpfs, otherwise the nix store's size will be bounded
      # by a fraction of available RAM.
      writableStoreUseTmpfs = false;

      # Because we want to test GRUB.
      # This may require `system-features = kvm` in your `nix.conf`, and your user
      # to be part of the `kvm` group, otherwise you may get:
      #     Could not access KVM kernel module: Permission denied
      # useBootLoader = true;
    };

    # So that we can ssh into the VM, see e.g.
    # http://blog.patapon.info/nixos-local-vm/#accessing-the-vm-with-ssh
    services.openssh.enable = true;
    services.openssh.permitRootLogin = "yes";

    services.csgods = {
      enable = true;
      user = "root";
      group = "root";
      stateDir = "/root/host";
      plugins = with csgo-plugins; [
        metamod-source
        sourcemod
        csgo-retakes
        csgo-practice-mode
        csgo-pug-setup
      ];
      configs = [
        (pkgs.writeText "server.cfg" ''
          rcon_password test
          sv_password lolnoobs
          sm_retakes_enabled 0
          sm_prac 0
        '')
        (pkgs.writeText "autoexec.cfg" ''
          sm_retakes_enabled 0
          sm_prac 0
          tv_enable 1
        '')
      ];
    };


    environment.systemPackages = with pkgs; [
      git
      htop
      vim
      nix-diff
    ];

    users.extraUsers.root.password = "";
    users.mutableUsers = false;
  };
}
