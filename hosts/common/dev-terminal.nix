# Shared interactive tooling for the Framework and laptop.
{ pkgs, lib, ... }:
let
  # NixOS's zoxide module has no Nushell integration. Vendor autoload runs
  # after the user's config.nu without replacing their existing configuration.
  zoxideNu = pkgs.runCommand "zoxide-nushell-autoload" { } ''
    mkdir -p "$out/share/nushell/vendor/autoload"
    ${lib.getExe pkgs.zoxide} init nushell > "$out/share/nushell/vendor/autoload/zoxide.nu"
  '';

  # Herdr uses $SHELL for local terminals and for agent command wrappers.
  # Keep the cwd selected by Herdr; nix-shell does not cd to the Nix file.
  devShell = pkgs.writeShellScript "herdr-dev-shell" ''
    shellFile="$HOME/base-nix/shells/dev/shell.nix"
    if [[ ! -f "$shellFile" ]]; then
      echo "herdr: missing dev shell: $shellFile" >&2
      exit 1
    fi

    # Herdr's agent launcher uses POSIX shell syntax with -ic/-lic. Execute
    # those arguments with Bash inside the same dev environment, not Nu.
    command='exec ${lib.getExe pkgs.nushell} --login'
    for arg in "$@"; do
      if [[ "$arg" == -*c* ]]; then
        printf -v command 'exec %q ' '${pkgs.bashInteractive}/bin/bash'
        printf -v args '%q ' "$@"
        command+="$args"
        break
      fi
    done
    exec ${pkgs.nix}/bin/nix-shell "$shellFile" --run "$command"
  '';

  herdrApp = pkgs.symlinkJoin {
    name = "herdr-app-dev";
    paths = [ pkgs.herdr-desktop ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/herdr-app" --set SHELL ${devShell}
    '';
  };
in
{
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  environment.systemPackages = [ zoxideNu herdrApp pkgs.herdr-core ];
}
