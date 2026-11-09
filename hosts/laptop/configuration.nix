# Laptop — AMD CPU + NVIDIA dGPU (CUDA), hybrid graphics.
#
# Same structure as hosts/framework (default.nix + rebuild.sh, 26.05
# option names, shared nix-ld/herdr-app libraries, dev tooling), with the
# laptop-specific parts kept: NVIDIA/CUDA, PRIME power management, touchpad,
# wacom, battery/power tuning.
#
# Deliberate differences from hosts/framework:
#   * system.stateVersion stays 23.11 — it must match this machine's *install*
#     release, not the framework's fresh 26.05 install. Do not bump it.
#   * kernel follows linuxPackages_latest. The NVIDIA driver comes from that
#     same kernel package set, so its module is built for the selected kernel.
#   * CUDA: nixpkgs.config.cudaSupport + the cuda-maintainers cache.

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../common/dev-terminal.nix
      ../common/cli.nix
      ../common/flatpak.nix
    ];

  # --------------------------------------------------------------- boot -----
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  # Latest packaged kernel (takes effect after reboot).
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # amd-pstate in active mode = best frequency scaling on the AMD CPU.
  boot.kernelParams = [ "amd_pstate=active" ];

  networking.hostName = "laptop";

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
  # Wi-Fi / Bluetooth / GPU firmware blobs.
  hardware.enableRedistributableFirmware = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # 32-bit Vulkan/OpenGL for Steam & Wine
  };

  # ------------------------------------------------------------- nvidia -----
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.powerManagement.enable = true;
  hardware.nvidia.powerManagement.finegrained = false;
  hardware.nvidia.open = false;
  hardware.nvidia.nvidiaSettings = true;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;

  nixpkgs.config.cudaSupport = true;

  nix.settings = {
    substituters = [ "https://cuda-maintainers.cachix.org" ];
    trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };

  # ------------------------------------------------------- power / thermal ---
  powerManagement.enable = true;
  powerManagement.powertop.enable = true;
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = false; # Intel-only

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  # Laptop firmware (EC/BIOS) through LVFS.
  services.fwupd.enable = true;

  # ------------------------------------------------------------ desktop -----
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  fonts.packages = with pkgs; [ nerd-fonts.fira-code roboto-mono cascadia-code ];

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Touchpad.
  services.libinput.enable = true;

  # Stylus.
  services.xserver.wacom.enable = true;

  services.printing.enable = false;

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
      joshuto
      nushell
      docker
      poetry
      tor-browser
      zed-editor
      zellij
      tmux
      helix
      unixtools.watch
      bat
      texliveFull
      yazi
      python3
      uv
      distrobox

      # rust
      rust-analyzer
      bacon
      cargo-wizard

      # GPU / monitoring (NVIDIA + battery)
      nvtopPackages.nvidia
      vulkan-tools
      mesa-demos
      lm_sensors
      pciutils
      usbutils
      powertop

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
    git-graph
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
  # Install release of this machine. Do NOT bump to 26.05 (that is the
  # framework's fresh install); stateVersion must stay at the release the
  # stateful data was created with.
  system.stateVersion = "23.11";

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
    # X11 key/window-management helpers, audio, notifications, DRM/GBM.
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
