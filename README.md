# base-nix

my nix dotfiles (WIP)

## Hosts

| Host        | Flake attr              | Notes                                        |
|-------------|-------------------------|----------------------------------------------|
| `default`   | `.#default`             | top-level `configuration.nix` (NVIDIA)       |
| `laptop`    | `.#laptop`              | laptop, NVIDIA                               |
| `desktop`   | `.#desktop`             | desktop, NVIDIA + CUDA                       |
| `framework` | `.#framework`           | Framework Desktop, full AMD (Ryzen AI Max)   |

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

```sh
git clone https://github.com/<you>/base-nix /mnt/home/nick/base-nix
# copy in the generated hardware config
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/home/nick/base-nix/hosts/framework/

cd /mnt/home/nick/base-nix
nix flake update          # REQUIRED: lockfile is from Oct 2024 (old kernel/Mesa)

# The live ISO does NOT enable flakes by default (the installed system does):
sudo NIX_CONFIG='experimental-features = nix-command flakes' \
  nixos-install --flake .#framework --root /mnt
```

After the first boot, confirm with `nix config show experimental-features`
(should print `flakes nix-command`).

`nixos-install` asks for a root password; set one, then reboot.

### 6. First boot

```sh
sudo nixos-rebuild switch --flake ~/base-nix#framework
passwd                       # set nick's password
fwupdmgr get-devices         # Framework BIOS/EC firmware updates via LVFS
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

- `hosts/framework` is the full-AMD host: no NVIDIA driver, no CUDA, no
  `cuda-maintainers` substituter. It enables `linuxPackages_latest`,
  `hardware.graphics` (32-bit included), firmware blobs, `fwupd`,
  `power-profiles-daemon`, Bluetooth, zram, Docker/libvirt and the Steam stack.
- ROCm is commented out in `hardware.graphics.extraPackages` — gfx1151 works
  with recent ROCm but the closure is huge. Add `"render"`/`"video"` to the
  user's `extraGroups` when enabling it (already done in the framework host).
- Rebuild any host with: `sudo nixos-rebuild switch --flake .#<host>`.
