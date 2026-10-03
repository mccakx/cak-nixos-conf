{ pkgs, lib, config, ... }: {

  options.cak.laptop.enable = lib.mkEnableOption ''
    laptop tweaks: power profiles, firmware updates, zram, battery-aware scheduler,
    AC/battery switching (power profile + MSI EC shift/fan mode)
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

    # Follow the power source: on battery -> power-saver profile (also lowers
    # amdgpu panel brightness/ABM and steers scx_lavd), and on MSI laptops with
    # msi-ec -> EC shift mode eco + silent fans. On AC -> balanced / comfort / auto.
    # Runs at boot and on every plug/unplug; manual changes (GNOME quick
    # settings, MControlCenter) stick until the next plug event.
    systemd.services.cak-power-source = {
      description = "Apply power settings for the current power source";
      after = [ "power-profiles-daemon.service" ];
      wants = [ "power-profiles-daemon.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.power-profiles-daemon pkgs.coreutils ];
      serviceConfig.Type = "oneshot";
      script = ''
        ac=0
        for s in /sys/class/power_supply/*; do
          if [ "$(cat "$s/type")" = Mains ] && [ "$(cat "$s/online")" = 1 ]; then ac=1; fi
        done
        if [ "$ac" = 1 ]; then
          profile=balanced; shift=comfort; fan=auto
        else
          profile=power-saver; shift=eco; fan=silent
        fi
        echo "AC=$ac -> profile=$profile shift=$shift fan=$fan"
        powerprofilesctl set "$profile" || true
        ec=/sys/devices/platform/msi-ec
        if [ -w "$ec/shift_mode" ]; then
          echo "$shift" > "$ec/shift_mode" || true
          echo "$fan" > "$ec/fan_mode" || true
        fi
      '';
    };
    services.udev.extraRules = ''
      SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ACTION=="change", RUN+="${pkgs.systemd}/bin/systemctl start --no-block cak-power-source.service"
    '';
  };
}
