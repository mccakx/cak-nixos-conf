# cak-nixos-conf

Personal NixOS configuration flake ("McCak NixOS Flake"). The whole system — kernel, services, desktop, user environment — is declared here and rebuilt reproducibly with flakes + Home Manager.

## Hosts

| Host | Description |
|---|---|
| `nixos-test` | QEMU/KVM VM guest — zen kernel, no gaming stack, zram swap (qemu-guest-agent, spice-vdagent) |
| `desktop` | Main machine — AMD GPU (LACT with overdrive, nvtop-amd), LAN bridge `br0` at 10.0.1.3 managed by NetworkManager, NTFS drive at `/drive/HDDWin1`, ext4 drive at `/drive/SSDLinux1`, AAGL launchers — 4K screen run at 1080p @ 125%, with Plymouth and the SDDM greeter set to match |
| `delta` | MSI laptop — AMD GPU (nvtop-amd), MControlCenter + out-of-tree msi-ec driver; single unencrypted disk mounted by label (see "Installing delta") |

Data drives are mounted with `nofail`, so a missing drive doesn't block boot.

All hosts share the common modules in `modules/` and a Home Manager config for user `cak` (`users/cak/home.nix`, `home/`).

## Flake inputs

- `nixpkgs` — `nixos-26.05`
- `nixpkgs-unstable` — selected packages pulled from unstable
- `nix-cachyos-kernel` — CachyOS kernel (`linuxPackages-cachyos-latest-x86_64-v3`, 7.2.x — see `modules/gaming.nix` for the TV HDMI caveat)
- `aagl` — anime-games-launcher (ezKEa/aagl-gtk-on-nix) for gacha games on NixOS
- `home-manager` — follows nixpkgs

Adding a host: create `hosts/<name>/` and register it in `flake.nix`'s `makeConfig`.

## What's configured

**Desktop:** KDE Plasma 6 + SDDM (Wayland), PipeWire (ALSA/Pulse/JACK), Firefox, KDE Connect, LocalSend. Plymouth boot splash (adi1090x `black_hud` theme with the NixOS logo added) with quiet boot.

**Gaming:** Steam (gamescope session, gamemode, Remote Play / LAN transfer firewall ports), OBS Studio with VAAPI + Wayland capture plugins, AAGL.

**Virtualization:** Podman (docker-compat, DNS-enabled network) + libvirtd (swtpm, virtiofsd) + virt-manager.

**System:**
- Gaming hosts (`cak.gaming.enable`): CachyOS latest kernel + sched_ext (`scx_lavd --performance`) scheduler
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

## Installing delta (fresh, wipes the disk)

`hosts/delta/hardware-configuration.nix` mounts by label (`BOOT`, `swap`,
`delta`), so no file needs editing on the machine. Boot the NixOS 26.05
minimal ISO, get online (`nmtui` for Wi-Fi), then as root:

```bash
lsblk                          # find the disk, e.g. /dev/nvme0n1
DISK=/dev/nvme0n1              # <-- double-check: everything on it is erased
SWAPEND=17GiB                  # 1GiB ESP + 16GiB swap; swap >= RAM for hibernation

wipefs -a $DISK
parted -s $DISK -- mklabel gpt \
  mkpart ESP fat32 1MiB 1GiB set 1 esp on \
  mkpart swap linux-swap 1GiB $SWAPEND \
  mkpart nixos btrfs $SWAPEND 100%
# nvme partitions are ${DISK}p1..p3, sata ones ${DISK}1..3
P=${DISK}p
mkfs.fat -F32 -n BOOT ${P}1
mkswap -L swap ${P}2 && swapon ${P}2
mkfs.btrfs -f -L delta ${P}3

mount ${P}3 /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/nix
umount /mnt
mount -o subvol=root,compress=zstd:3 /dev/disk/by-label/delta /mnt
mkdir -p /mnt/{home,nix,boot}
mount -o subvol=home,compress=zstd:3 /dev/disk/by-label/delta /mnt/home
mount -o subvol=nix,compress=zstd:3,noatime /dev/disk/by-label/delta /mnt/nix
mount -o fmask=0022,dmask=0022 /dev/disk/by-label/BOOT /mnt/boot

# sanity check: compare initrd modules with what the hardware reports
nixos-generate-config --root /mnt --show-hardware-config | grep -A1 availableKernelModules

# install; the extra caches serve the prebuilt CachyOS kernel + aagl
nixos-install --no-root-password --flake github:mccakx/cak-nixos-conf#delta \
  --option extra-experimental-features "nix-command flakes" \
  --option extra-substituters "https://attic.xuyh0120.win/lantian https://ezkea.cachix.org https://cache.xinux.uz" \
  --option extra-trusted-public-keys "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc= ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI= cache.xinux.uz:BXCrtqejFjWzWEB9YuGB7X2MV4ttBur1N8BkwQRdH+0="

reboot
```

After first login (`cak` / initial password `12345`): run `passwd`, then
check the MSI driver and open MControlCenter:

```bash
modinfo -n msi_ec                          # path should contain /updates/ (out-of-tree build)
cat /sys/devices/platform/msi-ec/fw_version # missing dir = EC firmware unsupported
```

If `fw_version` is missing, msi-ec doesn't know this laptop's EC firmware.
MControlCenter then falls back to raw `ec_sys` writes, which needs
`boot.kernelModules = [ "ec_sys" ]` + `boot.extraModprobeConfig = "options ec_sys write_support=1";` on delta.

## Automation

`.github/workflows/flake-update.yml` bumps `flake.lock` daily (01:00 Asia/Jakarta) via CI.
