{ config, lib, pkgs, inputs, ... } :

let
  nixpkgsUnstable = inputs.nixpkgs-unstable.legacyPackages."x86_64-linux";
in
{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/system.nix
      #inputs.aagl.nixosModules.default
    ];

  networking.hostName = "desktop"; # Define your hostname.
  networking.useDHCP = false;
  networking.bridges = {
    "br0" = {
      interfaces = [ "enp42s0" ];
    };
  };
  networking.interfaces.br0.ipv4.addresses = [ {
    address = "192.168.100.67";
    prefixLength = 24;
  } ];
  networking.interfaces.enp42s0.useDHCP = false;
  networking.defaultGateway = "192.168.100.1";
  networking.nameservers = ["9.9.9.9" "1.1.1.1" "8.8.8.8" "192.168.100.1"];

  environment.systemPackages = with pkgs; [
    (nixpkgsUnstable.lact)
    nvtopPackages.amd
  ];

  systemd.packages = with pkgs; [ (nixpkgsUnstable.lact) ];
  systemd.services.lactd.wantedBy = ["multi-user.target"];

  hardware.amdgpu.overdrive.enable = true;

  fileSystems."/drive/HDDWin1" = {
    device = "/dev/disk/by-uuid/2B0B486A2FDC92F6";
    fsType = "ntfs-3g";
    options = [ "rw uid=1000" ];
  };

  fileSystems."/drive/SSDWin1" = {
    device = "/dev/disk/by-uuid/3A3E10783E102F7F";
    fsType = "ntfs-3g";
    options = [ "rw uid=1000" ];
  };

  fileSystems."/drive/NVMEWin1" = {
    device = "/dev/disk/by-uuid/D058CDED58CDD280";
    fsType = "ntfs-3g";
    options = [ "rw uid=1000" ];
  };

  programs.sleepy-launcher.enable = true;
  programs.anime-game-launcher.enable = true;

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
