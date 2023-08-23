nix-cde-self:

{ sources
, default_build_system ? null
}:

project:

{ build_system ? default_build_system
, host_system ? build_system
, cross_system ? null
, is_shell ? false
, overlay ? self: super: {}
, self ? null
}:

let
  # Packages for the host (running) system
  pkgs = if (cross_system == null)
  then sources.nixpkgs.legacyPackages.${host_system}
  else (import sources.nixpkgs {
    localSystem = host_system;
    crossSystem = cross_system;
  });

  # Packages for the build system
  pkgs_native = sources.nixpkgs.legacyPackages.${build_system};
  lib = pkgs_native.lib;
  stdenv = pkgs_native.stdenv;

  nix-cde = nix-cde-self {
    inherit sources;
    default_build_system = build_system;
  };

  base_module = { config, ... }:
  {
    config._module.args = {
      inherit is_shell lib nix-cde pkgs pkgs_native sources stdenv;
      src = pkgs.nix-gitignore.gitignoreSource config.src_exclude config.src;
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
