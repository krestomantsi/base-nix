# Framework Desktop — full AMD (Ryzen AI Max / "Strix Halo", Radeon 8060S iGPU).
# No NVIDIA, no CUDA: the dGPU sections of the other hosts are intentionally absent.
#
# Strix Halo (gfx1151) needs kernel >= 6.15 and Mesa >= 25.1, so keep the
# channel current (`sudo nix-channel --update`) or use the pinned
# hosts/framework/nixpkgs.nix; an old channel cannot drive the GPU or the
# MT7925 Wi-Fi.

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../common/dev-terminal.nix
      # NOTE: ./vm.nix (GNOME Boxes/QEMU clipboard, shared folders, USB) is
      # intentionally *not* imported now that this runs on bare metal. Add the
      # line back if you boot this config in a VM:
      #   ./vm.nix
    ];

  # --------------------------------------------------------------- boot -----
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  # Newest mainline kernel from the pinned nixpkgs: required for the
  # Ryzen AI Max GPU, MT7925 Wi-Fi and the 5GbE NIC.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # amd-pstate in active mode = best frequency scaling on Zen 5.
  boot.kernelParams = [ "amd_pstate=active" ];

  networking.hostName = "framework";

  # ------------------------------------------------------------ network -----
  networking.networkmanager.enable = true;

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
  # Wi-Fi / Bluetooth / GPU firmware blobs (MT7925, amdgpu).
  hardware.enableRedistributableFirmware = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # 32-bit Vulkan/OpenGL for Steam & Wine
    # ROCm for the 8060S (gfx1151) is available but very large; uncomment if
    # you actually want it (also uncomment the render/video groups below):
    # extraPackages = with pkgs; [ rocmPackages.clr.icd ];
  };

  # Framework firmware updates (BIOS/EC) through LVFS.
  services.fwupd.enable = true;

  # Desktop-friendly power/thermal handling for AMD.
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = false;

  # Plenty of RAM on this box, but a small zram device keeps things snappy.
  zramSwap = {
    enable = true;
    memoryPercent = 15;
  };

  # ------------------------------------------------------------ desktop -----
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  fonts.packages = with pkgs; [ nerd-fonts.fira-code roboto-mono ];

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;

  # -------------------------------------------------------------- audio -----
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # -------------------------------------------------------------- users -----
  users.users.nick = {
    isNormalUser = true;
    description = "nick";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "render"
      "input"
      "docker"
      "libvirtd"
    ];
    packages = with pkgs; [
      # gnome
      gnome-boxes
      gnome-extension-manager
      gnome-tweaks
      gnomeExtensions.dash-to-dock
      gnomeExtensions.caffeine
      gnomeExtensions.blur-my-shell
      gnomeExtensions.logo-menu

      # general
      firefox-bin
      time
      neovim
      # nvim-treesitter needs the CLI to compile parsers; nvim itself is above.
      tree-sitter
      ranger
      git
      htop
      kitty
      eza
      telegram-desktop
      discord
      fzf
      starship
      lazygit
      libvirt
      libreoffice
      ripgrep
      nodejs
      fd
      alacritty
      unzip
      transmission_4-gtk
      xournalpp
      vlc
      typst
      zathura
      yazi
      nushell
      docker
      tor-browser
      zellij
      tmux
      wl-clipboard
      helix
      bat
      texliveFull
      python312
      uv
      yt-dlg
      distrobox

      # rust
      rust-analyzer
      bacon
      cargo-wizard

      # AMD GPU / monitoring
      amdgpu_top
      radeontop
      vulkan-tools
      mesa-demos
      nvtopPackages.amd
      lm_sensors
      pciutils
      usbutils

      # gaming
      mangohud
      goverlay
    ];
  };

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # NixOS defaults this to [ "man" "info" "doc" ]. With this nixpkgs pin the
  # python3.12 *doc* output does not build (sphinx 8 vs docutils 0.22 TypeError)
  # and is not in cache.nixos.org, which fails the whole system build. Keep
  # man/info pages, skip the doc outputs.
  environment.extraOutputsToInstall = lib.mkForce [ "man" "info" ];

  # ------------------------------------------------------- system packages --
  environment.systemPackages = with pkgs; [
    vim
    zsh-fzf-history-search
    # vscode 1.144 ships its bundled ripgrep at
    # node_modules.asar.unpacked/@vscode/ripgrep-universal/, but the nixpkgs
    # expression still rm/chmod's .../node_modules/@vscode/ripgrep/bin/rg and
    # fails (nothing in cache). Pre-create the path so the package's own
    # `rm` + `ln -s ${ripgrep}/bin/rg` succeeds.
    (vscode.overrideAttrs (old: {
      prePatch = (old.prePatch or "") + ''
        mkdir -p resources/app/node_modules/@vscode/ripgrep/bin
        touch resources/app/node_modules/@vscode/ripgrep/bin/rg
      '';
    }))
    protonup-ng
    lutris
    xdg-utils
    cmake
    gnumake
    libvterm
    libtool
    openssl.dev
    rustup
    zlib
    pkg-config
  ];

  # ------------------------------------------------------------ services ----
  services.openssh.enable = true;

  # --------------------------------------------------------- state version --
  # This value determines the NixOS release from which the default settings for
  # stateful data were taken. Leave it at the release of the first install.
  # 26.05 = current nixos-unstable, which is what the install ISO/README use.
  system.stateVersion = "26.05";

  # --------------------------------------------------------------- shell ----
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    ohMyZsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "robbyrussell";
    };
  };

  users.defaultUserShell = pkgs.nushell;
  users.users.nick.shell = pkgs.nushell;
  # nix-command = the `nix build` / `nix shell` / `nix profile` / `nix store`
  # subcommands; it does not involve lockfiles or inputs.
  nix.settings.experimental-features = [ "nix-command" ];

  # -------------------------------------------------------- virtualisation --
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  virtualisation.docker.enable = true;

  # ld fix
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    gcc
    glibc
    zlib
    cmake
    gnumake
    openssl
    # Prebuilt GUI binaries (herdr-app etc.): X11/Wayland + GPU + fonts.
    # herdr-app needs libxcb / libxkbcommon / libxkbcommon-x11 directly and
    # dlopens libvulkan, libEGL and libwayland-client at runtime.
    libxcb
    libxkbcommon
    libX11
    libXcursor
    libXrandr
    libXi
    libXinerama
    wayland
    vulkan-loader
    libGL
    libglvnd
    fontconfig
    freetype
    harfbuzz
    # More of what herdr-app / electron-ish prebuilt GUIs dlopen: X11 key and
    # window-management helpers, audio, notifications, DRM/GBM.
    libxcb-keysyms
    libxcb-wm
    alsa-lib
    libpulseaudio
    libnotify
    libdrm
    libgbm
  ];

  # herdr-app (multiplexer) + nvim as the editor: make every tool that shells
  # out pick nvim, including git commit messages and $EDITOR users.
  environment.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    GIT_EDITOR = "nvim";
  };

  # ------------------------------------------------------------- gaming -----
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    protontricks.enable = true;
  };
  programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = true;
  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    NIXOS_OZONE_WL = "1";
  };

  # ------------------------------------------------------------- nix gc -----
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 15d";
  };
  nix.settings.auto-optimise-store = true;
}
