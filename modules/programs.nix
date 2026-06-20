{ pkgs, lib, config, inputs, ... }: {

  programs = {
    firefox = {
      enable = true;
      preferences = {
        "widget.use-xdg-desktop-portal.file-picker" = 1;
      };
    };
    kdeconnect.enable = true;
    virt-manager.enable = true;
    partition-manager.enable = true;
    ssh = {
      startAgent = true;
      extraConfig = ''
        Host github.com
          IdentityFile ~/Downloads/SSH-Keys/github/id_ed25519
      '';
    };
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
    };

    gamescope.enable = true;
    gamemode.enable = true;
    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-pipewire-audio-capture
        obs-vaapi #optional AMD hardware acceleration
        obs-gstreamer
        obs-vkcapture
      ];
    };
  };

}
