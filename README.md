# base-nix

my nix dotfiles (WIP)

## Hosts

| Host        | Flake attr              | Notes                                        |
|-------------|-------------------------|----------------------------------------------|
| `default`   | `.#default`             | top-level `configuration.nix` (NVIDIA)       |
| `laptop`    | `.#laptop`              | laptop, NVIDIA                               |
| `desktop`   | `.#desktop`             | desktop, NVIDIA + CUDA                       |
| `framework` | `.#framework`           | Framework Desktop, full AMD (Ryzen AI Max), own `nixpkgs-latest` input |

## Two ways to build `framework`

| | Command | Needs |
|---|---|---|
| **No flakes** (default below) | `sudo ~/base-nix/hosts/framework/rebuild.sh` or `sudo nixos-rebuild switch -f hosts/framework/default.nix -I nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos` | a `nixos-unstable` channel (or `hosts/framework/nixpkgs.nix` pin) |
| Flakes | `sudo nixos-rebuild switch --flake .#framework` | `nix-command flakes` |

The host module itself (`hosts/framework/configuration.nix`) is identical for
both — it contains nothing flake-specific.

**Why two files:** `nixos-rebuild -f FILE` evaluates FILE and reads
`config.system.build.*` from it, so FILE must be a *system* expression →
`default.nix`. `nixos-install` instead passes the file as `-I nixos-config=`,
so it wants a *module* → `configuration.nix`.

### Non-flake files

- `hosts/framework/default.nix` — the `-f` entry point (system expression wrapping `configuration.nix`).
- `hosts/framework/bootloader-bios.nix` — imported by `default.nix` **only when `/sys/firmware/efi` is missing**; a BIOS install (e.g. the QEMU/Boxes test VM) keeps GRUB on `/dev/vda` instead of trying systemd-boot. Real UEFI hardware is unaffected and gets systemd-boot.
- `hosts/framework/rebuild.sh` — `switch` / `boot` / `--install`, picks up the pin automatically and passes `-I nixpkgs=<root channel>` because `sudo` drops `NIX_PATH`.
- `hosts/framework/nixpkgs.nix.example` — optional tarball pin; rename to `nixpkgs.nix` after filling in rev + sha256.
- `shells/dev/shell.nix` — **one dev shell with Odin (`odin` + `ols`), Rust (`rustup`) and Python (`uv`)**, plus `nvim`/`tree-sitter`/`ripgrep`/`fd` for the herdr-app + nvim workflow.
- `shells/rust_repo/shell.nix`, `shells/yggdrasil/shell.nix` — non-flake dev shells, copy/symlink into the repos.

```sh
# set up the channel once on the installed system
sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos
sudo nix-channel --update

# rebuild (run as root; rebuild.sh adds -I nixpkgs=<root channel> for you)
sudo ~/base-nix/hosts/framework/rebuild.sh
# or by hand
sudo nixos-rebuild switch -f ~/base-nix/hosts/framework/default.nix \
  -I nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos

# dev shells
nix-shell ~/base-nix/shells/dev/shell.nix        # odin + ols + rustup + uv + nvim
cp ~/base-nix/shells/rust_repo/shell.nix ~/rust_repo/
cp ~/base-nix/shells/yggdrasil/shell.nix ~/yggdrasil/
cd ~/rust_repo && nix-shell
cd ~/yggdrasil && nix-shell
```

## The laptop host (non-flake)

`hosts/laptop/` has the same shape as the framework host: `default.nix` (the
`-f` system expression), `configuration.nix` (the module), `rebuild.sh`.

```sh
sudo ~/base-nix/hosts/laptop/rebuild.sh
# or by hand
sudo nixos-rebuild switch -f ~/base-nix/hosts/laptop/default.nix \
  -I nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos
```

Same as the framework: 26.05 option names, `nix-ld` libraries for prebuilt GUI
apps (herdr-app), `EDITOR`/`VISUAL`/`GIT_EDITOR=nvim`, the `python3.12-doc` and
`vscode` build workarounds, Docker/libvirt, Steam + gamemode, zram, `fwupd`.

Kept laptop-specific, deliberately different from the framework:

| | laptop | framework |
|---|---|---|
| GPU | `services.xserver.videoDrivers = [ "nvidia" ]`, PRIME power management, `cudaSupport` + cuda cache | none (Radeon 8060S) |
| `system.stateVersion` | **23.11** (install release — never bump) | 26.05 (fresh install) |
| kernel | nixpkgs default, so the NVIDIA module matches | `linuxPackages_latest` |
| power | `powerManagement.enable`, powertop, zram 25%, `services.libinput` | `power-profiles-daemon`, zram 15% |
| extra | `services.xserver.wacom` (stylus), touchpad | — |

## Setting up the Framework Desktop

### 1. BIOS / firmware

1. Boot the machine and press **F2** to enter the BIOS.
2. **Security → Secure Boot → Disabled** (systemd-boot here is not signed).
   Re-enable later with `lanzaboote` if you want Secure Boot.
3. Check the BIOS version and update it via USB if it is older than the
   version listed on Framework's support page.
4. Set the boot order so USB comes first for the install.

### 2. Installer USB

Download the **NixOS unstable (GNOME or minimal) ISO** — 24.11/25.05 ISO
kernels are too old to drive the Radeon 8060S / MT7925 reliably:

```sh
# replace sdX with the USB stick (check with lsblk!)
sudo dd if=nixos-unstable.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

### 3. Partitioning (from the ISO)

```sh
sudo -i
lsblk                                  # identify the NVMe(s)

# GPT + 1G ESP + rest as root
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1025MiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart root ext4 1025MiB 100%

mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
mkfs.ext4 -L nixos /dev/nvme0n1p2

mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/BOOT /mnt/boot
```

### 4. Generate the real hardware config

```sh
nixos-generate-config --root /mnt
```

This writes `/mnt/etc/nixos/hardware-configuration.nix`. **Copy that file over
`hosts/framework/hardware-configuration.nix`** in this repo — the committed one
has placeholder UUIDs and will not boot as-is.

### 5. Get this repo onto the target and install

**Without flakes (channel-based):**

```sh
git clone https://github.com/krestomantsi/base-nix /mnt/home/nick/base-nix
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/home/nick/base-nix/hosts/framework/

# fresh nixpkgs on the live ISO (its bundled one can be old) and copy it to
# the target so the installed system has a channel
nix-channel --add https://nixos.org/channels/nixos-unstable nixos
nix-channel --update

# NOTE: nixos-install takes a MODULE via NIXOS_CONFIG, not -f
NIXOS_CONFIG=/mnt/home/nick/base-nix/hosts/framework/configuration.nix \
  nixos-install --root /mnt \
  -I nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos
```

or simply `./hosts/framework/rebuild.sh --install /mnt` from inside the repo.

`nixos-install` asks for a root password; set one, then reboot.

**With flakes:**

```sh
git clone https://github.com/krestomantsi/base-nix /mnt/home/nick/base-nix
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/home/nick/base-nix/hosts/framework/

cd /mnt/home/nick/base-nix

# The live ISO does NOT enable flakes by default (the installed system does).
# Export it once; it applies to every nix command in this shell:
export NIX_CONFIG='experimental-features = nix-command flakes'

# No `nix flake update` needed: the framework host uses its own `nixpkgs-latest`
# input, which nix resolves automatically here (first eval, needs network).
nixos-install --flake .#framework --root /mnt
```

If you'd rather make flakes permanent on the live ISO:

```sh
mkdir -p /etc/nix
echo 'experimental-features = nix-command flakes' >> /etc/nix/nix.conf
systemctl restart nix-daemon
```

After the first boot, confirm with `nix config show experimental-features`
(should print `flakes nix-command`).

`nixos-install` asks for a root password; set one, then reboot.

### 6. First boot

```sh
# non-flake
sudo ~/base-nix/hosts/framework/rebuild.sh
# or: sudo nixos-rebuild switch -f ~/base-nix/hosts/framework/default.nix \
#       -I nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos

passwd                       # set nick's password
fwupdmgr get-devices         # Framework BIOS/EC firmware updates via LVFS
```

If the channel wasn't copied during install, add it now:

```sh
sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos
sudo nix-channel --update
```

### 7. Sanity checks

```sh
lspci -k | grep -A3 -E 'VGA|3D'   # expect amdgpu + Radeon 8060S
vulkaninfo --summary              # expect RADV / gfx1151
sensors                           # amdgpu temps
ip -br a                          # 5GbE + Wi-Fi 7
bluetoothctl show
```

## Notes

- **Bare metal:** `hosts/framework/configuration.nix` no longer imports
  `vm.nix`, so no SPICE/QEMU guest services are enabled. Add `./vm.nix` back to
  `imports` if you boot this host in GNOME Boxes/QEMU.
- **Replace `hosts/framework/hardware-configuration.nix`** with the output of
  `nixos-generate-config` from the real machine (step 4). The tracked file is a
  template with placeholder UUIDs (an ESP on `/boot`, NVMe, AMD microcode);
  `rebuild.sh` refuses to `switch`/`boot` while those placeholders are there.
  The QEMU/Boxes test VM's generated file is kept as
  `hosts/framework/hardware-configuration.vm.nix` — copy it over the template
  when rebuilding the VM:
  `cp hosts/framework/hardware-configuration.vm.nix hosts/framework/hardware-configuration.nix`
- `system.stateVersion` is `26.05` (the release the unstable install ISO is on).
  Don't bump it later; it is not a nixpkgs pin.
- Bootloader: `configuration.nix` asks for systemd-boot (correct on the real
  Framework, which is UEFI). `default.nix` additionally imports
  `bootloader-bios.nix` when `/sys/firmware/efi` is absent, which keeps GRUB on
  `/dev/vda` for BIOS installs instead of failing on systemd-boot.
- `environment.extraOutputsToInstall` is forced to `[ "man" "info" ]`: with
  this nixpkgs pin the `python3.12-doc` output fails to build (sphinx/docutils)
  and is not in `cache.nixos.org`, which would break the whole system build.
- `vscode` is wrapped in `overrideAttrs` (see the comment in
  `configuration.nix`) because 1.144 moved its bundled ripgrep to
  `@vscode/ripgrep-universal` while nixpkgs still patches the old path.
- Editor/multiplexer: `EDITOR`/`VISUAL`/`GIT_EDITOR` are set to `nvim`, and the
  `programs.nix-ld` library list carries what prebuilt apps (`herdr-app`)
  dlopen: X11/xcb(+keysyms/wm)/xkbcommon, Wayland, vulkan, mesa/libGL, DRM/GBM,
  ALSA/PulseAudio, libnotify and fonts. `tree-sitter` is installed for
  nvim-treesitter.
- `hosts/framework` uses the `nixpkgs-latest` flake input instead of the main
  (Oct 2024) `nixpkgs` pin, because Strix Halo needs a recent kernel/Mesa. Nix
  resolves it on first eval; other hosts are untouched. Run
  `nix flake update nixpkgs-latest` on the Framework to move it forward later.
- `hosts/framework` is the full-AMD host: no NVIDIA driver, no CUDA, no
  `cuda-maintainers` substituter. It enables `linuxPackages_latest`,
  `hardware.graphics` (32-bit included), firmware blobs, `fwupd`,
  `power-profiles-daemon`, Bluetooth, zram, Docker/libvirt and the Steam stack.
- ROCm is commented out in `hardware.graphics.extraPackages` — gfx1151 works
  with recent ROCm but the closure is huge. Add `"render"`/`"video"` to the
  user's `extraGroups` when enabling it (already done in the framework host).
- `hosts/framework` targets **current unstable (26.05+)**: `services.desktopManager.gnome`,
  `services.displayManager.gdm`, `services.pulseaudio`, `transmission_4-gtk`,
  `protonup-ng`, `libglvnd`. On the old Oct-2024 pin those are `services.xserver.*` /
  `transmission-gtk` / `protonup` / `libEGL`, which is why the flake needs
  `nixpkgs-latest` (or `nix flake update`) rather than the committed lock.
- Prebuilt GUI apps (`herdr-app` etc.) run through `programs.nix-ld`, whose
  library list includes libxcb/libxkbcommon/X11/Wayland/vulkan/mesa/fonts/audio.
- Rebuild any host with: `sudo nixos-rebuild switch --flake .#<host>`, or for
  `framework` without flakes: `sudo ~/base-nix/hosts/framework/rebuild.sh`
  (equivalently `sudo nixos-rebuild switch -f hosts/framework/default.nix
  -I nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos`).
