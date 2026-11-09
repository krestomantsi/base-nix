# Framework Desktop — full AMD (Ryzen AI Max / "Strix Halo", Radeon 8060S iGPU).
# No NVIDIA, no CUDA: the dGPU sections of the other hosts are intentionally absent.
#
# Strix Halo (gfx1151) needs kernel >= 6.15 and Mesa >= 25.1. Like the laptop,
# rebuild.sh refreshes nixos-unstable on every build; an old channel cannot
# drive the GPU or the MT7925 Wi-Fi.

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../common/dev-terminal.nix
      ../common/cli.nix
      ../common/flatpak.nix
      # NOTE: ./vm.nix (GNOME Boxes/QEMU clipboard, shared folders, USB) is
      # intentionally *not* imported now that this runs on bare metal. Add the
      # line back if you boot this config in a VM:
      #   ./vm.nix
    ];

  # --------------------------------------------------------------- boot -----
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  # Latest packaged kernel for the Ryzen AI Max GPU, MT7925 Wi-Fi and
  # the 5GbE NIC (takes effect after reboot).
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
    # you actually want it (render/video groups are already included below):
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

  fonts.packages = with pkgs; [ nerd-fonts.fira-code roboto-mono cascadia-code ];

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
      gh
      htop
      kitty
      eza
      telegram-desktop
      fzf
      starship
      lazygit
      libvirt
      libreoffice
      ripgrep
      nodejs_latest
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
      helix
      bat
      texliveFull
      python3
      uv
      yt-dlg
      distrobox

      # rust
      # rust-analyzer

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

  # Keep man/info pages, but skip large or uncached documentation outputs.
  # These previously broke the system build with python3.12-doc.
  environment.extraOutputsToInstall = lib.mkForce [ "man" "info" ];

  # ------------------------------------------------------- system packages --
  environment.systemPackages = with pkgs; [
    vim
    zsh-fzf-history-search
    # Current unstable already fixes the bundled ripgrep path; use the
    # unmodified package so we can use its binary-cache build.
    vscode
    protonup-ng
    lutris
    xdg-utils
    # GNOME handles the clipboard; these expose it to CLI tools and editors.
    wl-clipboard # wl-copy / wl-paste in Wayland
    xclip        # legacy clients running through XWayland
    cmake
    gnumake
    libvterm
    libtool
    openssl.dev
    rustup
    zlib
    pkg-config
  ];

  # --------------------------------------------------------------- git -----
  # Default commit identity; user/repository Git config can override this.
  programs.git = {
    enable = true;
    config.user = {
      name = "Nick Lamprinidis";
      email = "nlamprinidis@eagle.org";
    };
  };

  # ------------------------------------------------------------ services ----
  services.openssh.enable = true;

  # --------------------------------------------------------- state version --
  # This value determines the NixOS release from which the default settings for
  # stateful data were taken. Leave it at the release of the first install.
  # 26.05 is this host's install release, not a package-version pin.
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
