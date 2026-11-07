# Shared CLI packages and quiet Nushell startup for every host.
{ pkgs, ... }:
let
  # Older channels lack pi; use the same immutable revision as shells/pi.
  pi = pkgs.pi-coding-agent or (import (builtins.fetchTarball
    "https://github.com/NixOS/nixpkgs/archive/40b88f09a5afd6ed3356df4ba4977c789036a69e.tar.gz") { }).pi-coding-agent;
  quietNu = pkgs.runCommand "nushell-quiet-startup" { } ''
    mkdir -p "$out/share/nushell/vendor/autoload"
    echo '$env.config.show_banner = false' > "$out/share/nushell/vendor/autoload/00-quiet.nu"
  '';
in
{
  environment.systemPackages = [ pi quietNu ];
}
