{ pkgs, lib, config, inputs, ... }:

{
  options.cak.gaming.enable = lib.mkEnableOption ''
    gaming stack: Steam, gamescope, gamemode, OBS, Proton tooling,
    CachyOS kernel + scx_bpfland scheduler
  '';

  config = lib.mkIf config.cak.gaming.enable {
    # TEMPORARY: pinned to CachyOS LTS (6.18.x). The -latest- kernel (7.2.0)
    # regressed amdgpu Display Core (v3.2.384 + new HDMI-FRL polling) so the
    # Navi 22 HDMI-A-1 connector never enumerates -> kwin "no outputs" -> blank
    # SDDM. Revert to -latest- once the DC HDMI-FRL fix ships in a released kernel.
    boot.kernelPackages =
      inputs.nix-cachyos-kernel.legacyPackages."x86_64-linux".linuxPackages-cachyos-lts-x86_64-v3;

    services.scx = {
      enable = true;
      scheduler = "scx_bpfland";
    };

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
    };

    programs.gamescope.enable = true;
    programs.gamemode.enable = true;
    programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-pipewire-audio-capture
        obs-vaapi # optional AMD hardware acceleration
        obs-gstreamer
        obs-vkcapture
      ];
    };

    environment.systemPackages = with pkgs; [
      mangohud
      vulkan-tools
      protonup-qt
      protontricks
      bottles
      umu-launcher
      jamesdsp
    ];
  };
}
