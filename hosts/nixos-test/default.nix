{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/system.nix
    ];

  networking.hostName = "nixos-test";

  # ------------------------------------------------------------------
  # Lightweight test VM: no gaming stack (cak.gaming.enable = false),
  # zen kernel. Desktop is Plasma 6 on Wayland, inherited from
  # modules/services.nix (SDDM Wayland + plasma6), matching the desktop
  # and delta hosts. Accessed via the virt-manager / Spice console.
  # ------------------------------------------------------------------

  cak.gaming.enable = false;

  boot.kernelPackages = pkgs.linuxPackages_zen;

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # compressed zram swap on top of the 8G swap partition (small VM)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Virtio-GPU: the guest needs nothing extra (mesa drives virtio-gpu
  # out of the box); in virt-manager set Video model = "virtio"
  # (and 3D acceleration if wanted -> requires /dev/dri/renderD128).

  system.copySystemConfiguration = false;

  system.stateVersion = "24.11";
}
