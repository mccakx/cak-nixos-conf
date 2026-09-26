{ pkgs, lib, config, inputs, ... }:

{
  options.cak.gaming.enable = lib.mkEnableOption ''
    gaming stack: Steam, gamescope, gamemode, OBS, Proton tooling,
    CachyOS kernel + scx_bpfland scheduler
  '';

  config = lib.mkIf config.cak.gaming.enable {
    # CachyOS -latest- (7.2.x). Needs the Samsung TV's "HDMI UHD Color" ON for
    # HDMI-A-1: with it off the TV sends an HDMI-1.4-style EDID (no HDMI Forum
    # block) and 7.2's new amdgpu HDMI-FRL status polling (DC v3.2.384) loses the
    # connector -> kwin "no outputs" -> blank SDDM. Upstream fix is queued for
    # Linux 7.4. If the display breaks, fall back to
    # linuxPackages-cachyos-lts-x86_64-v3 (6.18 LTS), which is unaffected.
    boot.kernelPackages =
      inputs.nix-cachyos-kernel.legacyPackages."x86_64-linux".linuxPackages-cachyos-latest-x86_64-v3;

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
