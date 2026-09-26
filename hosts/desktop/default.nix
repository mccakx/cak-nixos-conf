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

  cak.gaming.enable = true;

  # Let NetworkManager own the LAN bridge natively (instead of scripted
  # networking) so KDE reports a proper "Connected/Full" state instead of the
  # bogus "Limited connectivity" it shows for an externally-configured bridge.
  # VMs still bridge onto br0 at the kernel level; NM ignores their tap/vnet devices.
  networking.networkmanager.ensureProfiles.profiles = {
    br0 = {
      connection = {
        id = "br0";
        type = "bridge";
        interface-name = "br0";
        autoconnect = true;
        autoconnect-slaves = 1;   # bring the slave up with the bridge
      };
      bridge.stp = false;
      ipv4 = {
        method = "manual";
        address1 = "10.0.1.3/24,10.0.1.1";      # ADDRESS/PREFIX,GATEWAY
        dns = "10.0.1.1;9.9.9.9;1.1.1.1;";
      };
      ipv6.method = "disabled";
    };
    enp42s0 = {
      connection = {
        id = "enp42s0";
        type = "ethernet";
        interface-name = "enp42s0";
        master = "br0";
        slave-type = "bridge";
        autoconnect = true;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    (nixpkgsUnstable.lact)
    nvtopPackages.amd
  ];

  systemd.packages = with pkgs; [ (nixpkgsUnstable.lact) ];
  systemd.services.lactd.wantedBy = ["multi-user.target"];

  hardware.amdgpu.overdrive.enable = true;

  # Load amdgpu in the initrd (early KMS) so Plymouth draws on the real GPU.
  # Without it amdgpu only loads ~7s in, after switch-root, and its modeset
  # wipes the splash that Plymouth drew on the EFI simpledrm framebuffer.
  hardware.amdgpu.initrd.enable = true;

  # The 4K Samsung on HDMI-A-1 is run at 1920x1080 @ 125% (the GPU can't game
  # at 4K). Match that on the boot path too:
  # - Plymouth: start the console at 1080p and enlarge the splash 125%.
  boot.kernelParams = [ "video=HDMI-A-1:1920x1080@60" ];
  cak.plymouth.scale = 125;

  # - SDDM: the greeter's KWin (runs as user sddm) has no display settings of
  #   its own and falls back to native 4K at 100%. Give it the same output
  #   config as the Plasma session (what the SDDM KCM's "Apply Plasma
  #   Settings" button would copy from ~/.config/kwinoutputconfig.json).
  systemd.tmpfiles.rules =
    let
      sddmOutputConfig = pkgs.writeText "sddm-kwinoutputconfig.json" (builtins.toJSON [
        {
          name = "outputs";
          data = [{
            connectorName = "HDMI-A-1";
            edidIdentifier = "SAM 3578 16780800 1 2017 0";
            edidHash = "0335e1fb20d9d5a6f32b2231cfcfb407";
            mode = { width = 1920; height = 1080; refreshRate = 60000; flags = 0; };
            scale = 1.25;
            transform = "Normal";
          }];
        }
        {
          name = "setups";
          data = [{
            lidClosed = false;
            outputs = [{
              enabled = true;
              outputIndex = 0;
              position = { x = 0; y = 0; };
              priority = 0;
              replicationSource = "";
            }];
          }];
        }
      ]);
    in [
      "d /var/lib/sddm/.config 0755 sddm sddm -"
      "L+ /var/lib/sddm/.config/kwinoutputconfig.json - - - - ${sddmOutputConfig}"
    ];

  fileSystems."/drive/HDDWin1" = {
    device = "/dev/disk/by-uuid/2B0B486A2FDC92F6";
    fsType = "ntfs-3g";
    options = ["uid=1000" "windows_names" "nofail"];
  };

  fileSystems."/drive/SSDLinux1" = {
    device = "/dev/disk/by-uuid/03363123-77ce-4c24-9ae3-4a3bb9c23a73";
    fsType = "ext4";
    options = ["defaults" "noatime" "nofail" ];
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
