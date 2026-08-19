# dotfiles

Personal Nix flake for managing personal devices with Home Manager, powered by [nixos-unified](https://github.com/srid/nixos-unified).

## New Machine Setup

`scripts/bootstrap.sh` only installs what the OS doesn't already ship: Lix on
a system with no Nix at all, and Homebrew on macOS. A fresh **NixOS** install
already has Nix, so bootstrapping is a no-op there — clone and activate
directly:

```bash
# NixOS
git clone <repo> ~/.config/dotfiles
cd ~/.config/dotfiles
nix run .#activate
```

```bash
# macOS, or any non-NixOS Linux without Nix installed
git clone <repo> ~/.config/dotfiles
cd ~/.config/dotfiles

./scripts/bootstrap.sh   # installs Lix (+ Homebrew on macOS) if missing

# First run uses the nixos-unified app since `nh` is not yet on PATH.
nix run .#activate
```

## Usage

After the first activation, the shell aliases and `nh` utilities are available.

```bash
sw              # Rebuild and switch the current host
up              # Update pins/locks, check, and switch the current host
act [host]      # Activate through nixos-unified (also supports remote hosts)
bump            # Update flake.lock without switching
gc              # Safer GC (keeps last 5 generations + 3d)

nh search <pkg> # Fast nixpkgs search via nix-index

nix flake check # Validate evaluation and checks
```

Equivalent explicit commands:

```bash
nix run .#activate          # Match current hostname
nix run .#activate blender  # NixOS WSL host
nix run .#activate mixer    # macOS default profile
nix run .#activate juicer   # macOS development profile
nix run .#update            # Update nixpkgs, Home Manager, and nix-darwin only
```

## Container Runtime

Each darwin host selects exactly one container runtime in its configuration:

```nix
containerRuntime = "container"; # apple/container | "orbstack" | "podman"
```

`container` reuses the nixpkgs package, while its upstream version and source hash are pinned independently in the overlay because nixpkgs can lag behind [apple/container](https://github.com/apple/container) releases. `up` bumps it automatically on macOS; to bump it manually:

```bash
nix run .#update-pinned-packages
```

## Project Templates

Bootstrap a project from this flake's templates:

e.g. Rust project
```bash
mkdir example-rust-service && cd example-rust-service
nix flake init -t github:kohandy1902/dotfiles#rust
```

All templates expose `packages.default`, `apps.default`, `checks`, and a
`devShell`. Their Nix locks and language dependencies are intentionally updated
separately:

```bash
./scripts/update-templates.sh              # Nix flake locks only
./scripts/update-template-dependencies.sh  # Language dependency locks
```

## Home profiles

- `minimal`: CLI, shell, Git, direnv, and Nix tooling
- `headless`: minimal plus Neovim (see [Neovim](#neovim) below)
- `headless-development`: headless plus languages, containers, Kubernetes, and agents
- `development`: headless-development plus GUI editors, terminals, and desktop tools
- `default`: alias of development

## Neovim

Neovim itself is just a plain package (`programs.neovim.enable` is
deliberately *not* used — it would write its own managed `init.lua` into
`~/.config/nvim`, colliding with the setup below). The actual editor config
is [kohandy1902/LazyVim](https://github.com/kohandy1902/LazyVim), a personal
LazyVim fork, and it is **not** built or pinned by Nix at all:

- On first activation, if `~/.config/nvim` doesn't exist, a home-manager
  activation script (`cloneLazyVim` in `modules/home/headless.nix`) clones
  the fork there over SSH.
- Once it exists, Nix never touches it again — no re-sync on activate, no
  commit pinned in `flake.lock`.
- `~/.config/nvim` is a plain, ordinary git working directory: edit it, run
  `git pull` to update, `git commit`/`git push` from there like any other
  repo. `lazy-lock.json` is a normal writable file that `lazy.nvim` updates
  itself.

This trades reproducibility (two machines can end up on different commits of
the fork until you `git pull`) for a config you can edit and push to
directly on any machine, which fits a LazyVim setup — you're expected to
tweak it often — much better than re-deriving it in Nix (à la
[nixvim](https://github.com/nix-community/nixvim), which this repo used to
do and dropped for exactly this reason).
