# Raspberry Pi 5 (`raspberry`) — minimal ARM64 app host for ~/yggdrasil and
# ~/rust_repo, with the lightest practical Wayland desktop (Sway + greetd).
#
# Plain NixOS (`nixos-unstable`, no flakes). Use hosts/raspberry/rebuild.sh to
# refresh root's channel and switch/install.
#
# Notes:
#   * nixpkgs removed the old linuxPackages_rpi* series; mainline Linux 6.18+
#     (and linuxPackages_latest) handles Pi 5 directly.
#   * Boot defaults to UEFI (rpi5-uefi / EDK2 + systemd-boot). If booted via
#     U-Boot / standard NixOS ARM64 SD image without EFI, default.nix
#     automatically imports bootloader-extlinux.nix instead.
#   * All desktop/media/browser/gaming GUI packages are omitted; only Sway +
#     foot + wmenu + i3status are installed for a minimal local session.

{ config, pkgs, lib, ... }:

let
  # Compiled raygui shared library linked by yggdrasil's Odin binary.
  rayguiLib = pkgs.callPackage ../../shells/common/raygui.nix { };

  # NixOS's zoxide module has no Nushell integration; vendor autoload keeps
  # user config untouched without importing the desktop dev-terminal module.
  zoxideNu = pkgs.runCommand "zoxide-nushell-autoload" { } ''
    mkdir -p "$out/share/nushell/vendor/autoload"
    ${lib.getExe pkgs.zoxide} init nushell > "$out/share/nushell/vendor/autoload/zoxide.nu"
  '';
in
{
  imports = [
    ./hardware-configuration.nix
    ../common/cli.nix
    ./services/yggdrasil.nix
  ];

  # --------------------------------------------------------------- boot -----
  # Default to systemd-boot for Pi 5 UEFI (rpi5-uefi / EDK2). Leaving
  # canTouchEfiVariables = false avoids efibootmgr NVRAM quirks on Pi 5 UEFI
  # and installs the removable fallback binary cleanly.
  # Non-EFI boots (U-Boot / SD image) override this via bootloader-extlinux.nix.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = false;

  # Mainline latest kernel for Pi 5 (BCM2712, RP1 PCIe/Ethernet/USB, V3D, Wi-Fi).
  # Switch to pkgs.linuxPackages (6.18 LTS) if you prefer LTS over bleeding edge.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "raspberry";

  # ------------------------------------------------------------ network -----
  networking.networkmanager.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22   # SSH
      5151 # rust_repo (Loco server)
      5152 # yggdrasil HTTP server
    ];
    trustedInterfaces = [ "tailscale0" ];
  };

  # --------------------------------------------------------------- time -----
  time.timeZone = "Europe/Athens";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "el_GR.UTF-8";
    LC_IDENTIFICATION = "el_GR.UTF-8";
    LC_MEASUREMENT = "el_GR.UTF-8";
    LC_MONETARY = "el_GR.UTF-8";
    LC_NAME = "el_GR.UTF-8";
    LC_NUMERIC = "el_GR.UTF-8";
    LC_PAPER = "el_GR.UTF-8";
    LC_TELEPHONE = "el_GR.UTF-8";
    LC_TIME = "el_GR.UTF-8";
  };

  # ------------------------------------------------------------ hardware ----
  # Broadcom/Cypress Wi-Fi firmware (CYW43455) and other redistributable blobs.
  hardware.enableRedistributableFirmware = true;

  # Mesa V3D / VC4 KMS+DRM acceleration for Sway Wayland on Pi 5.
  hardware.graphics.enable = true;

  # Compressed RAM swap helps when hosting yggdrasil (~1.7 GB+ routing graph)
  # alongside rust_repo builds/containers on a Pi 5.
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # --------------------------------------------------- lightweight desktop --
  # Minimal TUI greeter (~2 MB RAM) launching Sway directly on TTY1 — no Xorg,
  # no GDM/LightDM, no PipeWire/PulseAudio, no Bluetooth, no desktop bloat.
  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings.default_session = {
      command = "${lib.getExe pkgs.tuigreet} --time --remember --cmd sway";
      user = "greeter";
    };
  };

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = false;
    xwayland.enable = false;
    # Override defaults to drop pulseaudio/brightnessctl/grim.
    extraPackages = with pkgs; [
      foot     # ultra-light Wayland terminal (Mod+Enter)
      wmenu    # ultra-light Wayland launcher (Mod+d)
      swaylock
      swayidle
      i3status
    ];
  };

  # Sway enables graphical-desktop defaults (PipeWire, speech-dispatcher, GTK
  # portals); turn them off so the Pi stays a minimal terminal/server desktop.
  services.pipewire.enable = false;
  services.pulseaudio.enable = false;
  services.speechd.enable = false;
  xdg.portal.enable = lib.mkForce false;

  fonts.packages = with pkgs; [ nerd-fonts.fira-code ];
  console.keyMap = "us";

  # -------------------------------------------------------------- users -----
  users.defaultUserShell = pkgs.nushell;

  users.users.nick = {
    isNormalUser = true;
    description = "nick";
    shell = pkgs.nushell;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "render"
      "input"
      "docker"
    ];
    packages = with pkgs; [
      # minimal CLI utilities (no GUI apps)
      neovim
      tree-sitter
      git
      gh
      tmux
      htop
      ripgrep
      fd
      fzf
      bat
      eza
      starship
      nushell
      unzip
      pciutils
      usbutils
    ];
  };

  # Allow unfree packages if needed by firmware or tooling.
  nixpkgs.config.allowUnfree = true;

  # Keep man/info pages, skip large/uncached doc outputs.
  environment.extraOutputsToInstall = lib.mkForce [ "man" "info" ];

  # ------------------------------------------------------- system packages --
  # Rust, Odin, and the native toolchains/libraries needed to build and host
  # ~/yggdrasil and ~/rust_repo (Docker + native builds + backups + uv scripts).
  environment.systemPackages = with pkgs; [
    zoxideNu
    wl-clipboard

    # Odin + yggdrasil hosting/build tools
    odin
    ols
    just
    sqlite
    curl
    gcc
    binutils

    # Rust + rust_repo hosting/build tools
    rustup
    pkg-config
    cmake
    gnumake
    openssl.dev
    zlib
    netcdf
    hdf5
    trunk
    wasm-bindgen-cli
    binaryen

    # Python (uv scripts in rust_repo/docker_setup.sh & yggdrasil helpers)
    uv
    python3

    # Archive helpers used by yggdrasil/backup_server.sh & rust_repo/docker_setup.sh
    gnutar
    gzip
  ];

  # --------------------------------------------------------------- git -----
  programs.git = {
    enable = true;
    config.user = {
      name = "Nick Lamprinidis";
      email = "nlamprinidis@eagle.org";
    };
  };

  # --------------------------------------------------------------- shell ----
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };

  environment.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    GIT_EDITOR = "nvim";
  };

  # ------------------------------------------------------------ services ----
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };

  services.tailscale.enable = true;

  # Docker for ~/rust_repo/docker_setup.sh (runs rust-server-instance on :5151).
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Runtime libraries for uv's managed CPython and dynamically linked yggdrasil
  # binaries (yggdrasil compiles GUI+server into one Odin binary that links
  # libcurl, raylib, raygui, and GL/X11/Wayland even when running `serve`).
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    glibc
    zlib
    openssl
    sqlite
    curl
    netcdf
    hdf5
    raylib
    rayguiLib
    libGL
    libx11
    libxrandr
    libxi
    libxcursor
    libxinerama
    wayland
    libxkbcommon
  ];

  # --------------------------------------------------------- state version --
  # Install release of this host. Leave at the release of the first install.
  system.stateVersion = "26.11";

  # ------------------------------------------------------------- nix gc -----
  nix.settings.experimental-features = [ "nix-command" ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 15d";
  };
}
