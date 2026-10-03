{ pkgs, lib, config, ... }:

let
  cfg = config.cak.desktop;
in
{
  options.cak.desktop = lib.mkOption {
    type = lib.types.enum [ "plasma" "gnome" ];
    default = "plasma";
    description = "Desktop environment: Plasma 6 + SDDM, or GNOME + GDM (both Wayland).";
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg == "plasma") {
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
      services.desktopManager.plasma6.enable = true;
      programs.kdeconnect.enable = true;
      programs.partition-manager.enable = true;
      environment.systemPackages = [ pkgs.kdePackages.filelight ];
    })

    (lib.mkIf (cfg == "gnome") {
      services.displayManager.gdm.enable = true;
      services.desktopManager.gnome.enable = true;

      # KDE Connect protocol, GNOME edition (opens the same firewall ports)
      programs.kdeconnect = {
        enable = true;
        package = pkgs.gnomeExtensions.gsconnect;
      };

      environment.systemPackages = with pkgs; [
        gnome-tweaks
        gnomeExtensions.appindicator # tray icons (MControlCenter, Steam, ...)
      ];

      # Default-enable the extensions for every user (users can still turn them off)
      programs.dconf.profiles.user.databases = [{
        settings."org/gnome/shell".enabled-extensions = [
          "appindicatorsupport@rgcjonas.gmail.com"
          "gsconnect@andyholmes.github.io"
        ];
      }];
    })
  ];
}
