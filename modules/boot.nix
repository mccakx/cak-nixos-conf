{ pkgs, lib, config, inputs, ...} :
{
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };
    efi.canTouchEfiVariables = true;
  };
  # kernel selection: the gaming-tuned CachyOS kernel comes from
  # modules/gaming.nix (cak.gaming.enable); non-gaming hosts use the
  # default nixpkgs kernel or set their own here.
}
