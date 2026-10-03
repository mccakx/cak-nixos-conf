{ config, lib, pkgs, inputs, ... } :

{

  imports =
    [
      ./hardware-configuration.nix
      ../../modules/system.nix
    ];

  networking.hostName = "delta"; # Define your hostname.

  cak.gaming.enable = true;
  cak.laptop.enable = true;
  cak.desktop = "gnome";

  # Hibernate to the 32G swap partition (16G RAM)
  boot.resumeDevice = "/dev/disk/by-label/swap";

  # MSI laptop control (fan curves, battery threshold, cooler boost).
  # MControlCenter is in stable 26.05. Its root helper is a D-Bus system
  # service, so the package must also be registered with dbus or the GUI
  # can't read/write the EC. It uses the msi-ec driver below
  # and only falls back to raw ec_sys writes if msi-ec doesn't load.
  environment.systemPackages = with pkgs; [
    nvtopPackages.amd
    mcontrolcenter
  ];
  services.dbus.packages = [ pkgs.mcontrolcenter ];

  # Out-of-tree msi-ec (BeardOverflow) instead of the in-kernel one: mainline
  # msi-ec only knows ~27 EC firmware versions, this one ~140. Installed into
  # the module tree's updates/ dir, so it takes priority over the in-tree module.
  boot.kernelModules = [ "msi-ec" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.msi-ec ];

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
  system.stateVersion = "26.05"; # Did you read the comment?

}
