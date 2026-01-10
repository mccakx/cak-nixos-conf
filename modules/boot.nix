{ pkgs, lib, config, inputs, ...} :
let
  nixpkgsUnstable = inputs.nixpkgs-unstable.legacyPackages."x86_64-linux";
  cachyosKernel = inputs.nix-cachyos-kernel.legacyPackages."x86_64-linux";
in
{
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 3;
    };
    efi.canTouchEfiVariables = true;
  };
  boot.kernelPackages = cachyosKernel.linuxPackages-cachyos-latest-lto-x86_64-v3;
  #boot.kernelPackages = pkgs.linuxPackages_zen;


}
