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
  # Headless by default; the GNOME desktop is the `desktop` specialisation below.
  cak.desktop = "none";
  services.xserver.enable = lib.mkForce false; # services.nix turns it on
  systemd.defaultUnit = "multi-user.target";
  # keep running with the lid closed
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

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
    (pkgs.writeShellScriptBin "cak-mode" ''
      p=/nix/var/nix/profiles/system
      case "$1" in
        server)  sw=$p/bin/switch-to-configuration ;;
        desktop) sw=$p/specialisation/desktop/bin/switch-to-configuration ;;
        *) echo "usage: cak-mode server|desktop" >&2; exit 1 ;;
      esac
      # transient unit: survives the switch killing this terminal's session
      # logind isn't restarted by a switch, so the lid setting only applies after this
      sudo systemd-run --collect --pipe -E NIXOS_INSTALL_BOOTLOADER=1 \
        sh -c '"$0" switch && systemctl restart systemd-logind' "$sw"
    '')
  ];
  services.dbus.packages = [ pkgs.mcontrolcenter ];

  # Out-of-tree msi-ec (BeardOverflow) instead of the in-kernel one: mainline
  # msi-ec only knows ~27 EC firmware versions, this one ~140. Installed into
  # the module tree's updates/ dir, so it takes priority over the in-tree module.
  boot.kernelModules = [ "msi-ec" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.msi-ec ];

  # Desktop mode: a boot-menu entry + live switch, same kernel as the server
  # base so no reboot is needed. Toggle with `cak-mode server|desktop`.
  specialisation.desktop.configuration = {
    cak.desktop = lib.mkForce "gnome";
    services.xserver.enable = lib.mkOverride 40 true; # beats the base's mkForce false
    systemd.defaultUnit = lib.mkForce "graphical.target";
    services.logind.settings.Login = {
      HandleLidSwitch = lib.mkForce "suspend";
      HandleLidSwitchExternalPower = lib.mkForce "suspend";
      HandleLidSwitchDocked = lib.mkForce "ignore";
    };
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
  system.stateVersion = "26.05"; # Did you read the comment?

}
