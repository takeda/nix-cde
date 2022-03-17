{ sources
, default_host_system ? null
}:

project:

{ host_system ? default_host_system
, is_shell ? false
}:

let
  npmlock2nix_overlay = (self: super: {
    npmlock2nix = self.callPackage sources.npmlock2nix {};
  });
  pkgs = import sources.nixpkgs {
    config = {};
    overlays = [
      sources.poetry2nix.overlay
      npmlock2nix_overlay
    ];
    system = host_system;
  };
  lib = pkgs.lib;

  base_module = { config, ... }:
  {
    config._module.args = {
      inherit pkgs lib is_shell;
      src = pkgs.nix-gitignore.gitignoreSource ["*.nix\n"] config.src;
      nix-cde = import ./nix-cde.nix { inherit sources; default_host_system = host_system; };
    };
  };

  modules = lib.evalModules {
    modules = [
      base_module
      ./main.nix
      project
    ];
    specialArgs = {
      modulesPath = toString ./.;
    };
  };

in {
  inherit modules;
  outputs = modules.config;
}
