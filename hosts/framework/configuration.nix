# Framework Desktop — full AMD (Ryzen AI Max / "Strix Halo", Radeon 8060S iGPU).
# No NVIDIA, no CUDA: the dGPU sections of the other hosts are intentionally absent.
#
# NOTE: the pinned nixpkgs in flake.lock is from Oct 2024. Strix Halo (gfx1151)
# needs kernel >= 6.15 and Mesa >= 25.1, so run `nix flake update` before
# building this host (see the setup notes at the bottom of the repo README).

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
  hardware.pulseaudio.enable = false;
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
      microsoft-edge
      neovim
      ranger
      git
      julia-bin
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
      transmission-gtk
      xournalpp
      vlc
      typst
      zathura
      joshuto
      yazi
      nushell
      docker
      poetry
      tor-browser
      zed-editor
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

  # ------------------------------------------------------- system packages --
  environment.systemPackages = with pkgs; [
    vim
    zsh-fzf-history-search
    vscode
    protonup
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
  system.stateVersion = "24.11";

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
  ];

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
