# Declarative replacement for ~/yggdrasil/install_server_service.sh on the Pi 5.
#
# Build the binary inside the yggdrasil shell so Odin gets the right linker
# flags for curl, raylib, and compiled raygui:
#   nix-shell ~/base-nix/shells/yggdrasil/shell.nix --run 'cd ~/yggdrasil && ./build_server.sh'
#
# Runtime state stays outside the Nix store on purpose:
#   binary   ~/.local/bin/yggdrasil          (built by build_server.sh)
#   config   ~/.config/yggdrasil/server.env  (mode 600, never in the store)
#   data     $HOME                           (WorkingDirectory)
#
# Tip for Raspberry Pi 5 (4 Cortex-A76 cores): set YGGDRASIL_THREADS=4 (or 8)
# and YGGDRASIL_BIND=0.0.0.0 in ~/.config/yggdrasil/server.env.
{ config, pkgs, lib, ... }:

let
  user = "nick";
  home = "/home/${user}";
  bin = "${home}/.local/bin/yggdrasil";
  envFile = "${home}/.config/yggdrasil/server.env";
  rayguiLib = pkgs.callPackage ../../../shells/common/raygui.nix { };
  runtimeLibPath = lib.makeLibraryPath [
    pkgs.stdenv.cc.cc.lib
    pkgs.zlib
    pkgs.curl
    pkgs.raylib
    rayguiLib
    pkgs.libGL
    pkgs.libx11
    pkgs.libxrandr
    pkgs.libxi
    pkgs.libxcursor
    pkgs.libxinerama
    pkgs.wayland
    pkgs.libxkbcommon
  ];
in
{
  systemd.services.yggdrasil = {
    description = "yggdrasil data HTTP server";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      HOME = home;
      LD_LIBRARY_PATH = runtimeLibPath;
    };

    # Do not fail boot before ~/yggdrasil/build_server.sh has installed the binary.
    unitConfig.ConditionPathExists = bin;

    serviceConfig = {
      Type = "simple";
      User = user;
      Group = "users";
      WorkingDirectory = home;
      # "-" = do not fail the unit if the file is missing yet
      EnvironmentFile = "-${envFile}";
      ExecStart = "${bin} serve";
      LimitMEMLOCK = "infinity";
      LimitNOFILE = 65536;
      MemoryAccounting = true;
      MemoryMax = "80%";
      TimeoutStopSec = 30;
      Restart = "on-failure";
      RestartSec = 3;
    };
  };

  # Daily backup of the database and account-owned model artifacts.
  systemd.services.yggdrasil-backup = {
    description = "yggdrasil backup (database + account models)";
    after = [ "yggdrasil.service" ];
    path = with pkgs; [
      sqlite
      gnutar
      gzip
      coreutils
      procps
    ];
    environment.HOME = home;
    unitConfig.ConditionPathExists = "${home}/yggdrasil/backup_server.sh";
    serviceConfig = {
      Type = "oneshot";
      User = user;
      Group = "users";
      EnvironmentFile = "-${envFile}";
      ExecStart = "${home}/yggdrasil/backup_server.sh";
      Nice = 10;
      IOSchedulingClass = "idle";
    };
  };

  systemd.timers.yggdrasil-backup = {
    description = "Daily yggdrasil backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };
  };
}
