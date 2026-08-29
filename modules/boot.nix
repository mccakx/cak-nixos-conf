{ pkgs, lib, config, inputs, ...} :
{
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };
    efi.canTouchEfiVariables = true;
  };

  # Graphical boot splash. Breeze theme to match Plasma 6 / SDDM.
  boot.plymouth = {
    enable = true;
    theme = "breeze";
    themePackages = [ pkgs.kdePackages.breeze-plymouth ];
  };

  # Quiet the console so Plymouth's splash isn't overwritten by kernel/udev logs,
  # and hand off smoothly to SDDM.
  boot.kernelParams = [ "quiet" "splash" "rd.udev.log_level=3" "udev.log_priority=3" ];
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;

  # kernel selection: the gaming-tuned CachyOS kernel comes from
  # modules/gaming.nix (cak.gaming.enable); non-gaming hosts use the
  # default nixpkgs kernel or set their own here.
}
