{
  config,
  lib,
  pkgs,
  ...
}:

let
  nvimConfig = "${config.home.homeDirectory}/.config/nvim";
in
{
  imports = [
    ./minimal.nix
  ];

  # Plain package, not `programs.neovim.enable`: that home-manager module
  # writes its own managed init.lua into ~/.config/nvim, which would collide
  # with the LazyVim clone below.
  home.packages = [ pkgs.neovim ];

  # ~/.config/nvim is a plain git clone of the LazyVim fork - edit and push
  # to it directly on this machine. Nix only bootstraps the clone if the
  # directory is missing; once it exists, nothing here manages its contents
  # (no pinned commit, no sync-on-activate - update via `git pull` yourself).
  home.activation.cloneLazyVim = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    if [ ! -e "${nvimConfig}" ]; then
      mkdir -p "$(dirname "${nvimConfig}")"
      # Activation runs with a minimal PATH that doesn't include `ssh`, so
      # git's ssh transport needs to be pointed at it explicitly.
      GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh" \
        ${pkgs.git}/bin/git clone git@github.com:kohandy1902/LazyVim.git "${nvimConfig}"
    fi
  '';
}
