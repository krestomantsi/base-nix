# Declarative replacement for ~/yggdrasil/install_server_service.sh.
#
# The binary is still built by ~/yggdrasil/build_server.sh (fast, native,
# incremental-ish); only the *deployment* becomes declarative: unit, env file,
# memory limits and the daily backup timer are owned by NixOS.
#
# Import from hosts/framework/configuration.nix:
#   imports = [ ... ./services/yggdrasil.nix ];
#
# Then: sudo nixos-rebuild switch -f ~/base-nix/hosts/framework/default.nix
#
# Runtime state stays outside the store on purpose:
#   binary   ~/.local/bin/yggdrasil          (built by build_server.sh)
#   config   ~/.config/yggdrasil/server.env  (mode 600, never in the store)
#   data     $HOME                           (WorkingDirectory)
{ config, pkgs, lib, ... }:

let
  user = "nick";
  home = "/home/${user}";
  bin = "${home}/.local/bin/yggdrasil";
  envFile = "${home}/.config/yggdrasil/server.env";
in
{
  systemd.services.yggdrasil = {
    description = "yggdrasil data HTTP server";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    environment.HOME = home;

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
    environment.HOME = home;
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
