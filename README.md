# cak-nixos-conf

Personal NixOS configuration flake ("McCak NixOS Flake"). The whole system — kernel, services, desktop, user environment — is declared here and rebuilt reproducibly with flakes + Home Manager.

## Hosts

| Host | Description |
|---|---|
| `nixos-test` | QEMU/KVM VM guest — zen kernel, no gaming stack, zram swap (qemu-guest-agent, spice-vdagent) |
| `desktop` | Main machine — AMD GPU (LACT with overdrive, nvtop-amd), LAN bridge `br0` at 10.0.1.3 managed by NetworkManager, NTFS drive at `/drive/HDDWin1`, ext4 drive at `/drive/SSDLinux1`, AAGL launchers |
| `delta` | Secondary machine — AMD GPU (nvtop-amd), MSI tooling (mcontrolcenter), NTFS drive at `/drive/SSD1` |

Data drives are mounted with `nofail`, so a missing drive doesn't block boot.

All hosts share the common modules in `modules/` and a Home Manager config for user `cak` (`users/cak/home.nix`, `home/`).

## Flake inputs

- `nixpkgs` — `nixos-26.05`
- `nixpkgs-unstable` — selected packages pulled from unstable
- `nix-cachyos-kernel` — CachyOS kernel (`linuxPackages-cachyos-lts-x86_64-v3`, pinned to LTS — see `modules/gaming.nix`)
- `aagl` — anime-games-launcher (ezKEa/aagl-gtk-on-nix) for gacha games on NixOS
- `home-manager` — follows nixpkgs

Adding a host: create `hosts/<name>/` and register it in `flake.nix`'s `makeConfig`.

## What's configured

**Desktop:** KDE Plasma 6 + SDDM (Wayland), PipeWire (ALSA/Pulse/JACK), Firefox, KDE Connect, LocalSend. Plymouth boot splash (Breeze) with quiet boot.

**Gaming:** Steam (gamescope session, gamemode, Remote Play / LAN transfer firewall ports), OBS Studio with VAAPI + Wayland capture plugins, AAGL.

**Virtualization:** Podman (docker-compat, DNS-enabled network) + libvirtd (swtpm, virtiofsd) + virt-manager.

**System:**
- Gaming hosts (`cak.gaming.enable`): CachyOS LTS kernel + sched_ext (`scx_bpfland`) scheduler
- Btrfs with zstd compression on `/`, `/home`, `/nix`; monthly auto-scrub; weekly GC keeping 14 days of generations
- udev rules setting I/O schedulers per disk type (BFQ for HDDs, mq-deadline for SSDs, none for NVMe)
- NetworkManager; firewall opens SSH (22), WireGuard (51820), LocalSend and Steam ports
- OpenSSH with root login disabled
- Custom eduroam patch applied to wpa_supplicant (`modules/eduroam.patch`)
- plasma-workspace override merging XDG_DATA_DIRS into one directory (fixes app discovery under the Qt wrapper)

**User (Home Manager):** vesktop, qbittorrent, filezilla, tmux (mouse on), btop.

## Usage

```bash
# apply this machine's config
sudo nixos-rebuild switch --flake .#<hostname>

# update flake.lock
nix flake update

# garbage-collect old generations
nix-collect-garbage --delete-older-than 14d
```

## Automation

`.github/workflows/flake-update.yml` bumps `flake.lock` daily (01:00 Asia/Jakarta) via CI.
