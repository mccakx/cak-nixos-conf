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
          IdentityFile ~/.ssh/github_ed25519
          IdentitiesOnly yes
      '';
    };
    localsend = {
      enable = true;
      openFirewall = true;
    };
    # gaming stack (steam/gamescope/gamemode/OBS) lives in modules/gaming.nix
    # behind the cak.gaming.enable toggle
  };

  # 26.05: gcr-ssh-agent is enabled by default and conflicts with
  # programs.ssh.startAgent above (only one SSH agent allowed)
  services.gnome.gcr-ssh-agent.enable = false;

}
