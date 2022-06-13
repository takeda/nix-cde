{ sources
, default_build_system ? null
}:

project:

{ build_system ? default_build_system
, host_system ? build_system
, is_shell ? false
, cross_compile ? false
, overlay ? self: super: {}
, self ? null
}:

let
  overlays = [
    (self: super: {
      nix-cde.mkCDE = import ./nix-cde.nix {
        inherit sources;
        default_build_system = build_system;
      };
      npmlock2nix = self.callPackage sources.npmlock2nix {};
      nix-bundle-lib = sources.nix-bundle.lib { nixpkgs = self; };
    })
    sources.poetry2nix.overlay
    sources.gomod2nix.overlays.default
    sources.naersk.overlay
    overlay
  ];
  pkgs_base = options: import sources.nixpkgs ({
    inherit overlays;
    config = {};
  } // options);

  # Packages for the host (running) system
  pkgs = pkgs_base (if cross_compile then {
    localSystem = build_system;
    crossSystem = host_system;
  } else {
    localSystem = host_system;
  });

  # Packages for the build system
  pkgs_native = pkgs_base {
    localSystem = build_system;
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
      inherit self;
      modulesPath = toString ./.;
    };
  };

in {
  inherit modules;
  outputs = modules.config;
}
