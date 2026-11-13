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

  # Herdr's zstd-sys build probes for system zstd through pkg-config.
  # Keep this dependency scoped to Herdr; don't change the Rust dev shell/toolchain.
  herdrDesktop = pkgs.herdr-desktop.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.zstd ];
  });

  herdrApp = pkgs.symlinkJoin {
    name = "herdr-app-dev";
    paths = [ herdrDesktop ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/herdr-app" --set SHELL ${devShell}
    '';
  };

  # Precompute the full compiler, linker, pkg-config and tool environment from
  # shells/dev/shell.nix (odin, ols, just, rustup/cargo, uv, gcc, binutils,
  # raylib, raygui, curl, sqlite, openssl, etc.) so VS Code, its extensions,
  # integrated terminals and tasks see the nix-shell without running Electron
  # inside a transient nix-shell TMPDIR.
  devShellDrv = import ../../shells/dev/shell.nix { inherit pkgs; };

  vscodeDevEnv = pkgs.runCommand "vscode-dev-env.sh" {
    inherit (devShellDrv) nativeBuildInputs buildInputs;
  } ''
    cleanPath=""
    IFS=: read -ra dirs <<< "${pkgs.bashInteractive}/bin:$PATH"
    for d in "''${dirs[@]}"; do
      [[ -z "$d" || "$d" == "${pkgs.bashNonInteractive}/bin" ]] && continue
      case ":$cleanPath:" in
        *":$d:"*) ;;
        *) cleanPath="''${cleanPath:+$cleanPath:}$d" ;;
      esac
    done

    cleanLdFlags="''${NIX_LDFLAGS#-rpath $out/lib }"
    cleanLdFlags="''${cleanLdFlags#-rpath $out/lib}"
    devLibPath="${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib pkgs.zlib pkgs.libGL pkgs.libx11 ]}"

    {
      echo "export __ETC_PROFILE_DONE=1"
      echo "export __NIXOS_SET_ENVIRONMENT_DONE=1"
      echo "export IN_NIX_SHELL=impure"
      printf 'devShellPath=%q\n' "$cleanPath"
      echo 'case ":''${PATH:-}:" in'
      echo '  *":$devShellPath:"*) ;;'
      echo '  *) export PATH="$devShellPath''${PATH:+:$PATH}" ;;'
      echo 'esac'
      echo 'unset devShellPath'
      for var in \
        AR AS CC CXX LD NM OBJCOPY OBJDUMP RANLIB READELF SIZE STRINGS STRIP \
        PKG_CONFIG PKG_CONFIG_PATH \
        CMAKE_INCLUDE_PATH CMAKE_LIBRARY_PATH NIXPKGS_CMAKE_PREFIX_PATH \
        NIX_CC NIX_BINTOOLS NIX_CFLAGS_COMPILE \
        "''${!NIX_CC_WRAPPER_TARGET_HOST_@}" \
        "''${!NIX_BINTOOLS_WRAPPER_TARGET_HOST_@}" \
        "''${!NIX_PKG_CONFIG_WRAPPER_TARGET_HOST_@}"; do
        if [[ -n "''${!var:-}" ]]; then
          printf "export %s=%q\n" "$var" "''${!var}"
        fi
      done
      printf "export NIX_LDFLAGS=%q\n" "$cleanLdFlags"
      echo 'export CARGO_HOME="''${CARGO_HOME:-$HOME/.cargo}"'
      echo 'export RUSTUP_HOME="''${RUSTUP_HOME:-$HOME/.rustup}"'
      printf 'devLibPath=%q\n' "$devLibPath"
      echo 'case ":''${LD_LIBRARY_PATH:-}:" in'
      echo '  *":$devLibPath:"*) ;;'
      echo '  *) export LD_LIBRARY_PATH="$devLibPath''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ;;'
      echo 'esac'
      echo 'unset devLibPath'
    } > "$out"
  '';

  vscodeDev = pkgs.symlinkJoin {
    name = "vscode-dev";
    paths = [ pkgs.vscode ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/code" \
        --run "if [[ -r /etc/vscode-dev-env.sh ]]; then source /etc/vscode-dev-env.sh; else source ${vscodeDevEnv}; fi" \
        --set BASH_ENV "/etc/vscode-dev-env.sh"
    '';
  };
in
{
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  environment.etc."vscode-dev-env.sh".source = vscodeDevEnv;

  programs.bash.interactiveShellInit = ''
    if [[ -n "''${VSCODE_INJECTION:-}" || "''${TERM_PROGRAM:-}" == "vscode" ]] && [[ -r /etc/vscode-dev-env.sh ]]; then
      source /etc/vscode-dev-env.sh
    fi
  '';

  environment.systemPackages = [ zoxideNu herdrApp pkgs.herdr-core vscodeDev ];
}
