{ sources
, default_build_system ? null
}:

project:

{ build_system ? default_build_system
, host_system ? build_system
, is_shell ? false
, overlay ? self: super: {}
}:

let
  overlays = [
    (self: super: {
      nix-cde.mkCDE = import ./nix-cde.nix {
        inherit sources;
        default_build_system = build_system;
      };
      npmlock2nix = self.callPackage sources.npmlock2nix {};
    })
    sources.poetry2nix.overlay
    sources.gomod2nix.overlay
    sources.naersk.overlay
    overlay
  ];
  pkgs = import sources.nixpkgs {
    inherit overlays;
    config = {};
    system = host_system;
  };
  pkgs_native = import sources.nixpkgs {
    inherit overlays;
    config = {};
    system = build_system;
  };
  lib = pkgs_native.lib;

  base_module = { config, ... }:
  {
    config._module.args = {
      inherit pkgs pkgs_native lib is_shell sources;
      src = pkgs.nix-gitignore.gitignoreSource ["*.nix\nflake.lock\n"] config.src;
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
