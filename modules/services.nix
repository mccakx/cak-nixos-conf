{ pkgs, lib, config, inputs, ...} : {

  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
    };
    displayManager = {
    	sddm.enable = true;
    	sddm.wayland.enable = true;
    	};
    desktopManager.plasma6.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    openssh.enable = true;
    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/" ];
    };
    scx = {
      enable = true;
      scheduler = "scx_bpfland";
    };
    udev.extraRules = builtins.readFile ./rules;
  };

}
