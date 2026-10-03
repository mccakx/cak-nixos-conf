{ pkgs, lib, config, inputs, ...} : {

  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
    };
    # display manager + desktop: modules/desktop.nix (cak.desktop)

    # Printing: driverless (IPP Everywhere / AirPrint) over the network via
    # Avahi and over USB via ipp-usb, plus classic drivers for older printers.
    printing = {
      enable = true;
      drivers = with pkgs; [
        gutenprint   # Epson/Canon/many inkjets
        hplip        # HP
        splix        # Samsung/Xerox lasers
        brlaser      # Brother lasers
        epson-escpr
        epson-escpr2
      ];
    };
    ipp-usb.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    openssh = {
      enable = true;
      settings.PermitRootLogin = "no";
    };
    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/" ];
    };
    udev.extraRules = builtins.readFile ./rules;
  };

}
