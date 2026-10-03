{ pkgs, lib, config, ... }: {

  options.cak.laptop.enable = lib.mkEnableOption ''
    laptop tweaks: power profiles, firmware updates, zram, battery-aware scheduler
  '';

  config = lib.mkIf config.cak.laptop.enable {
    # Power profiles (GNOME/Plasma quick settings drive this). Not TLP: the two conflict.
    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;
    services.fwupd.enable = true;

    # Compressed RAM swap first (priority 5), disk swap partition as overflow
    # and for hibernation (priority -2 by default).
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 50;
    };

    # gaming.nix pins scx_lavd --performance for the desktop. On battery that
    # just burns power; --autopower follows the active power profile instead.
    services.scx.extraArgs = lib.mkIf config.cak.gaming.enable (lib.mkForce [ "--autopower" ]);
  };
}
