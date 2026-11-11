# Shared dev terminal tooling

`dev-terminal.nix` is imported by both Framework and laptop configurations.

- Zoxide is initialized in interactive Bash and Zsh, and through Nushell's
  vendor autoload directory. Use `z <directory>` or `zi` (fzf is installed by
  both hosts). Your existing Nushell configuration is not overwritten.
- `herdr-desktop` supplies the `herdr-app` binary and GNOME launcher;
  `herdr-core` supplies `hc`. Both are managed by Nix, not an upstream installer.
- The wrapped `herdr-app` sets its own `SHELL` to a dev-shell launcher. New
  local terminals run `nix-shell "$HOME/base-nix/shells/dev/shell.nix"` and then
  interactive Nushell, keeping the directory selected in Herdr. Agent `-c`
  commands use Bash inside the same dev environment for POSIX compatibility.
  Other terminal apps and your default login shell are unchanged.
- VS Code's `code` launcher is wrapped with `rustup` (including its `cargo`
  proxy), `odin`, `ols` and `uv` on `PATH`. This works for GNOME launches,
  extensions and integrated terminals on both hosts without putting Electron
  inside `nix-shell`. Install a Rust toolchain with `rustup default stable` if
  you have not already; for the full build/linker environment, enter
  `nix-shell ~/base-nix/shells/dev/shell.nix` in a project terminal.

Apply on each machine with its `hosts/<host>/rebuild.sh`, then open a new
terminal for zoxide. Quit any already-running VS Code and Herdr apps before
relaunching them (existing Code windows keep their old environment).
Existing persistent core sessions/terminals may retain their old shell or
configuration; stop/restart those sessions when switching to this setup.
Remote terminals use the remote machine's environment and are not changed.

The checkout must exist at `~/base-nix`. The first dev terminal can take time
while Nix downloads/builds the development tools. Inside a new Herdr terminal,
check `$env.IN_NIX_SHELL`, `which odin`, `which uv`, and `which rustup`.
