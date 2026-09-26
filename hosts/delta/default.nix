{ config, lib, pkgs, inputs, ... } :

let
  nixpkgsUnstable = inputs.nixpkgs-unstable.legacyPackages."x86_64-linux";
in
  {

  imports =
    [
      ./hardware-configuration.nix
      ../../modules/system.nix
    ];

  networking.hostName = "delta"; # Define your hostname.

  cak.gaming.enable = true;

  environment.systemPackages = with pkgs; [
    nvtopPackages.amd
    (nixpkgsUnstable.mcontrolcenter)
  ];

  fileSystems."/drive/SSD1" = {
    device = "/dev/disk/by-uuid/F6964AB9964A79DF";
    fsType = "ntfs-3g";
    options = [ "rw" "uid=1000" "nofail" ];
  };

  #nixpkgs.hostPlatform = {
  #  gcc.arch = "znver3";
  #  gcc.tune = "znver3";
  #  system = "x86_64-linux";
  #};

  #nix.settings.system-features = [
  #  "nixos-test"
  #  "benchmark"
  #  "big-parallel"
  #  "kvm"
  #  "gccarch-znver3"
  #];

  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = false;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?

}
