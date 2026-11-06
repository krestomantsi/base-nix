# base-nix

my nix dotfiles (WIP)

Plain NixOS: `<nixpkgs>` from a channel, `nixos-rebuild -f`, `nix-shell`.
No flake files, no lockfile.

## Hosts

| Host | Config | Rebuild |
|---|---|---|
| `framework` | `hosts/framework/` — Framework Desktop, full AMD (Ryzen AI Max / Strix Halo) | `sudo ~/base-nix/hosts/framework/rebuild.sh` |
| `laptop` | `hosts/laptop/` — AMD CPU + NVIDIA dGPU, CUDA | `sudo ~/base-nix/hosts/laptop/rebuild.sh` |
| `desktop` | `hosts/desktop/` — NVIDIA + CUDA (**not migrated yet**: old option names, `nerdfonts`, `transmission-gtk`, `protonup`, `libEGL`) | — |
| `default` | top-level `configuration.nix` (**not migrated yet**, same issues) | — |

## How a host is built

**Why two files per host:** `nixos-rebuild -f FILE` evaluates FILE and reads
`config.system.build.*` from it, so FILE must be a *system* expression →
`default.nix`. `nixos-install` instead passes the file as `-I nixos-config=`,
so it wants a *module* → `configuration.nix`.

```sh
# set up the channel once on the installed system
sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos
sudo nix-channel --update

# rebuild (run as root; rebuild.sh adds -I nixpkgs=<root channel> for you)
sudo ~/base-nix/hosts/framework/rebuild.sh
sudo ~/base-nix/hosts/laptop/rebuild.sh

# or by hand
sudo nixos-rebuild switch -f ~/base-nix/hosts/framework/default.nix \
  -I nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos
```

`rebuild.sh` takes `switch` (default), `boot`, `test`, or `--install /mnt`.

## Files

- `hosts/<host>/configuration.nix` — the NixOS module (all settings).
- `hosts/<host>/default.nix` — the `-f` entry point (system expression wrapping the module).
- `hosts/<host>/hardware-configuration.nix` — `nixos-generate-config` output.
- `hosts/<host>/rebuild.sh` — `switch` / `boot` / `test` / `--install`, passes `-I nixpkgs=<root channel>` because `sudo` drops `NIX_PATH`.
- `hosts/framework/bootloader-bios.nix` — imported by `default.nix` **only when `/sys/firmware/efi` is missing**; a BIOS install (e.g. the QEMU/Boxes test VM) keeps GRUB on `/dev/vda` instead of trying systemd-boot. Real UEFI hardware is unaffected.
- `hosts/framework/hardware-configuration.vm.nix` — the QEMU/Boxes machine's scan; copy it over `hardware-configuration.nix` when rebuilding the VM.
- `hosts/framework/nixpkgs.nix.example` — optional tarball pin; rename to `nixpkgs.nix` after filling in rev + sha256, and `rebuild.sh` will use it instead of the channel.
- `hosts/framework/services/yggdrasil.nix` — declarative yggdrasil service + backup timer (see below; not imported yet).
- `hosts/framework/vm.nix` — SPICE/QEMU guest integration (clipboard, shared folders, USB) for testing in GNOME Boxes; not imported on bare metal.
- `hosts/framework/diagnose.sh` — build once, print only the failing derivation(s), keyword matches and `df -h / /nix`.
- `shells/dev/shell.nix` — **one dev shell with Odin (`odin` + `ols`), Rust (`rustup`) and Python (`uv`)**, plus `nvim`/`tree-sitter`/`ripgrep`/`fd` for the herdr-app + nvim workflow.
- `shells/rust_repo/shell.nix`, `shells/yggdrasil/shell.nix` — dev shells, copy/symlink into the repos.
- `shells/pi/shell.nix` — a shell with a current `pi`, independent of the channel (pinned tarball).

```sh
# dev shells
nix-shell ~/base-nix/shells/dev/shell.nix        # odin + ols + rustup + uv + nvim
cp ~/base-nix/shells/rust_repo/shell.nix ~/rust_repo/
cp ~/base-nix/shells/yggdrasil/shell.nix ~/yggdrasil/
cd ~/rust_repo && nix-shell
cd ~/yggdrasil && nix-shell
nix-shell ~/base-nix/shells/pi/shell.nix --run "pi --version"
```

## The laptop host

Same shape as the framework host. Same 26.05 option names, `nix-ld` libraries
for prebuilt GUI apps (herdr-app), `EDITOR`/`VISUAL`/`GIT_EDITOR=nvim`, the
`python3.12-doc` and `vscode` build workarounds, Docker/libvirt, Steam +
gamemode, zram, `fwupd`.

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

Download the **NixOS unstable (GNOME or minimal) ISO** — older release ISO
kernels cannot drive the Radeon 8060S / MT7925 reliably:

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

### 6. First boot

```sh
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

## Deploying apps on the host

- **yggdrasil**: `hosts/framework/services/yggdrasil.nix` is a declarative
  replacement for the unit-writing half of `~/yggdrasil/install_server_service.sh`
  (server unit, memory limits, daily backup timer). The binary is still built by
  `~/yggdrasil/build_server.sh`. Import it from the host:

  ```nix
  imports = [ ... ./services/yggdrasil.nix ];
  ```

- **rust_repo**: keep `~/rust_repo/docker_setup.sh` for building/loading the
  image. To have the container start on boot, declare it:

  ```nix
  virtualisation.oci-containers.containers.rust-server = {
    image = "rust-server-app:latest";
    volumes = [
      "/home/nick/onedrive/data_sources:/mnt/onedrive/data_sources:ro"
      "rust-server-peer-benchmarking:/usr/app/projects/peer_benchmarking/IMO_DCS"
    ];
    ports = [ "5152:5152" ];
  };
  ```

- Never move runtime state into Nix: `$HOME`, `server.env` (mode 600), the
  routing graph, SQLite files and model artifacts stay outside the store.

## Notes

- **Bare metal:** `hosts/framework/configuration.nix` does not import `vm.nix`,
  so no SPICE/QEMU guest services are enabled. Add `./vm.nix` back to `imports`
  if you boot this host in GNOME Boxes/QEMU.
- **Replace `hosts/framework/hardware-configuration.nix`** with the output of
  `nixos-generate-config` from the real machine (step 4). The tracked file is a
  template with placeholder UUIDs (an ESP on `/boot`, NVMe, AMD microcode);
  `rebuild.sh` refuses to `switch`/`boot` while those placeholders are there.
  The QEMU/Boxes test VM's generated file is kept as
  `hosts/framework/hardware-configuration.vm.nix` — copy it over the template
  when rebuilding the VM:
  `cp hosts/framework/hardware-configuration.vm.nix hosts/framework/hardware-configuration.nix`
- `system.stateVersion` is `26.05` on the framework (the release the unstable
  install ISO is on) and `23.11` on the laptop (its install release). It is not
  a nixpkgs pin — don't bump it.
- Bootloader: `configuration.nix` asks for systemd-boot (correct on the real
  Framework, which is UEFI). `default.nix` additionally imports
  `bootloader-bios.nix` when `/sys/firmware/efi` is absent, which keeps GRUB on
  `/dev/vda` for BIOS installs instead of failing on systemd-boot.
- `environment.extraOutputsToInstall` is forced to `[ "man" "info" ]`: with
  this nixpkgs the `python3.12-doc` output fails to build (sphinx/docutils)
  and is not in `cache.nixos.org`, which would break the whole system build.
- `vscode` is wrapped in `overrideAttrs` (see the comment in
  `configuration.nix`) because 1.144 moved its bundled ripgrep to
  `@vscode/ripgrep-universal` while nixpkgs still patches the old path.
- `microsoft-edge` is dropped: its build fails and is not in the binary cache.
- Editor/multiplexer: `EDITOR`/`VISUAL`/`GIT_EDITOR` are set to `nvim`, and the
  `programs.nix-ld` library list carries what prebuilt apps (`herdr-app`)
  dlopen: X11/xcb(+keysyms/wm)/xkbcommon, Wayland, vulkan, mesa/libGL, DRM/GBM,
  ALSA/PulseAudio, libnotify and fonts. `tree-sitter` is installed for
  nvim-treesitter.
- `nix.settings.experimental-features = [ "nix-command" ]` — that is the `nix`
  subcommand family (`nix build`, `nix shell`, `nix profile`, `nix store`), not
  the flake feature.
- `hosts/framework` is the full-AMD host: no NVIDIA driver, no CUDA, no
  `cuda-maintainers` substituter. It enables `linuxPackages_latest`,
  `hardware.graphics` (32-bit included), firmware blobs, `fwupd`,
  `power-profiles-daemon`, Bluetooth, zram, Docker/libvirt and the Steam stack.
- ROCm is commented out in `hardware.graphics.extraPackages` — gfx1151 works
  with recent ROCm but the closure is huge. Add `"render"`/`"video"` to the
  user's `extraGroups` when enabling it (already done in the framework host).
- `hosts/framework` and `hosts/laptop` target **current unstable (26.05+)**:
  `services.desktopManager.gnome`, `services.displayManager.gdm`,
  `services.pulseaudio`, `services.libinput`, `transmission_4-gtk`,
  `protonup-ng`, `libglvnd`. On an older channel those are `services.xserver.*` /
  `transmission-gtk` / `protonup` / `libEGL` — so keep the channel current with
  `sudo nix-channel --update`.
- `hosts/desktop` and the top-level `configuration.nix` still use the old
  option names and removed packages; they need the same migration before they
  will evaluate.
