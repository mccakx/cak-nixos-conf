{ pkgs, lib, config, inputs, ...} : {

  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
    };
    # display manager + desktop: modules/desktop.nix (cak.desktop)
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
