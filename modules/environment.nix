{ pkgs, lib, config, inputs, unstable, ... }:

{
  environment = {
    systemPackages = with pkgs; [

      gcc
      vlc
      handbrake
      mpv

      # Archives
      zip
      unzip
      p7zip
      unrar
      rar

      # Filesystem
      ntfs3g
      exfat
      nfs-utils
      exfatprogs
      btrfs-progs
      f2fs-tools

      # Miscellaneous utilities
      libnotify
      xdg-utils
      git
      # pull the config and stage it for next boot (not a live switch)
      (writeShellScriptBin "update-nixos" ''
        set -euo pipefail
        cd "$HOME/cak-nixos-conf"
        git fetch
        git pull --ff-only
        sudo nixos-rebuild boot --flake ".#$(hostname)"
      '')
      wget
      libarchive
      sof-firmware
      podman-compose
      distrobox
      pciutils
      fastfetch
      tio
      dconf-editor
      remmina
      inetutils
      gparted-full
      
      # Spice tools
      spice
      spice-gtk
      spice-protocol
      spice-vdagent

      unstable.protonplus
      kdiskmark
      mono
    ];

    etc.hosts.mode = "0644";
    variables.EDITOR = "nano";

  };

}
