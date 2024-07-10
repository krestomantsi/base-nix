# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Athens";

  # Select internationalisation properties.
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

  # hyprland
  # services.xserver.enable = true;
  # services.displayManager.sddm.enable = true;
  # services.displayManager.sddm.wayland.enable = true;
  # programs.hyprland.enable = true;
  # programs.thunar.enable = true;
  # programs.waybar.enable = true;
  # hardware.bluetooth.enable = true; # enables support for Bluetooth
  # hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  # Enable the X11 windowing system.
  # Enable the GNOME Desktop Environment.
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  # fonts
  fonts.packages = with pkgs; [ nerdfonts roboto-mono ];

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nick = {
    isNormalUser = true;
    description = "nick";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    # gnome
    gnome.gnome-boxes
    gnome-extension-manager
    gnome-tweaks
    gnomeExtensions.dash-to-dock
    gnomeExtensions.caffeine
    gnomeExtensions.blur-my-shell
    gnomeExtensions.useless-gaps
    gnomeExtensions.logo-menu
    gnomeExtensions.rounded-window-corners
    gnomeExtensions.media-controls
      # hyprland
      # wofi
      # rofi
      # swaybg
      # pavucontrol
      # blueberry
      # grim
      # slurp
      # networkmanagerapplet
      # mako
      # loupe
      # wl-clipboard-rs
      #
      firefox
      time
      microsoft-edge
      neovim 
      ranger
      git
      rust-analyzer
      rustup
      julia-bin
      htop
      kitty
      zoxide
      eza
      telegram-desktop
      discord
      fzf
      emacs
      texliveFull
      ghostscript
      mupdf
      poppler
      starship
      lazygit
      libvirt
      libreoffice
      ripgrep
      engauge-digitizer
      tmux
      gfortran
      fortran-fpm
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
      docker
      poetry
      gnuplot
      tor-browser
      zed-editor
      pandoc
    ];
  };

  # wacom enable
  services.xserver.wacom.enable = true;

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  (catppuccin-gtk.override {
    accents = [ "pink" ]; # You can specify multiple accents here to output multiple themes
    size = "compact";
    tweaks = [ "rimless" "black" ]; # You can also specify multiple tweaks here
    variant = "mocha";
  })
  zsh-fzf-history-search
  vscode
  protonup
  lutris
  xdg-utils
  cmake
  gnumake
  libvterm
  libtool
  openssl
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  # zsh 
  programs.zsh = {
  enable = true;
  enableCompletion = true;
  autosuggestions.enable = true;
  syntaxHighlighting.enable = true;

  # Your zsh config
  ohMyZsh = {
    enable = true;
    plugins = [ "git" ];
    theme = "robbyrussell";
  };
 };

 users.defaultUserShell = pkgs.zsh;
 users.users.nick.shell = pkgs.zsh;
 nix.settings.experimental-features = [ "nix-command" "flakes" ];

 virtualisation.libvirtd.enable = true;
 programs.virt-manager.enable = true;

 # ld fix
 programs.nix-ld.enable = true;
 programs.nix-ld.libraries = with pkgs; [
   # Add any missing dynamic libraries for unpackaged
   # programs here, NOT in environment.systemPackages
   gcc
   glibc
   zlib
   cmake
   gnumake
   openssl
 ];

 # steam stuff
 programs.steam = {
  enable = true;
  remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
  dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
 };
 programs.steam.gamescopeSession.enable = true;
 programs.gamemode.enable = true;
 environment.sessionVariables = {
  STEAM_EXTRA_COMPAT_TOOLS_PATHS =
    "\${HOME}/.steam/root/compatibilitytools.d";
 };

 # cuda stuff
 nixpkgs.config.cudaSupport = true;
 services.xserver.videoDrivers = ["nvidia"];
  hardware.graphics = {
    enable = true;
  };

  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.powerManagement.enable = false;
  hardware.nvidia.powerManagement.finegrained = false;
  hardware.nvidia.open = false;
  hardware.nvidia.nvidiaSettings = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
