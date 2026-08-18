{
  flake,
  lib,
  modulesPath,
  pkgs,
  ...
}:

let
  inherit (flake.inputs) self;
  personal = import (self + /personal.nix);
  username = "dh-koh";
in
{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ./capitol-workspace.nix
    ./nvidia.nix

    self.nixosModules.minimal
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  dotfiles.primaryUser = username;

  proxmoxLXC = {
    manageHostName = true;
    # Keep the Proxmox-side network definition outside this Git flake.
    manageNetwork = false;
  };

  networking.hostName = "ws-dh-koh";
  networking.networkmanager.enable = lib.mkForce false;
  time.timeZone = personal.timezone;

  services.tailscale.enable = true;

  # Keep OpenSSH as a break-glass path if Tailscale SSH is unavailable.
  services.openssh.enable = lib.mkForce true;
  services.openssh.startWhenNeeded = lib.mkForce false;

  powerManagement.enable = lib.mkForce false;

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.specialFileSystems."/sys/kernel/debug".enable = lib.mkForce false;
  boot.specialFileSystems."/sys/kernel/tracing".enable = lib.mkForce false;

  # Matches the account's existing uid/gid on this host (see git history /
  # incident notes for ws-dh-koh): NixOS never renumbers an existing local
  # user, so these must track reality rather than an aspirational value.
  users.groups.${username}.gid = 11001;
  users.groups.shared.gid = 20001;
  users.users.${username} = {
    isNormalUser = true;
    uid = 11001;
    group = username;
    extraGroups = [
      "wheel"
      "shared"
    ];
    shell = pkgs.zsh;
    subUidRanges = [
      {
        startUid = 11002;
        count = 54535;
      }
    ];
    subGidRanges = [
      {
        startGid = 11002;
        count = 54535;
      }
    ];
  };

  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  home-manager = {
    backupFileExtension = "backup";
    users.${username} = {
      imports = [
        self.homeModules.base
        self.homeModules.headless-development
      ];
      dotfiles.home.username = username;
    };
  };

  system.stateVersion = "25.11";
}
