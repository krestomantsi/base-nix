# Laptop — AMD CPU + NVIDIA dGPU (CUDA), hybrid graphics.
#
# Same structure as hosts/framework (non-flake entry point + rebuild.sh, 26.05
# option names, shared nix-ld/herdr-app libraries, dev tooling), with the
# laptop-specific parts kept: NVIDIA/CUDA, PRIME power management, touchpad,
# wacom, battery/power tuning.
#
# Deliberate differences from hosts/framework:
#   * system.stateVersion stays 23.11 — it must match this machine's *install*
#     release, not the framework's fresh 26.05 install. Do not bump it.
#   * kernel stays on nixpkgs' default (not linuxPackages_latest) so the NVIDIA
#     module tracks a kernel it is built against. Uncomment to chase the newest
#     kernel anyway.
#   * CUDA: nixpkgs.config.cudaSupport + the cuda-maintainers cache.

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # --------------------------------------------------------------- boot -----
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  # boot.kernelPackages = pkgs.linuxPackages_latest; # see header note

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

  fonts.packages = with pkgs; [ nerd-fonts.fira-code roboto-mono ];

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
      htop
      kitty
      zoxide
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
      joshuto
      nushell
      docker
      poetry
      tor-browser
      zed-editor
      zellij
      tmux
      wl-clipboard
      helix
      unixtools.watch
      bat
      texliveFull
      julia-bin
      yazi
      python312
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

  # NixOS defaults this to [ "man" "info" "doc" ]. With this nixpkgs pin the
  # python3.12 *doc* output does not build and is not in cache.nixos.org, which
  # fails the whole system build. Keep man/info pages, skip the doc outputs.
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
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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
