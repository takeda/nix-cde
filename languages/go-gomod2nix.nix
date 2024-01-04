{ config, lib, sources, src, pkgs, ... }:

{
  options = with lib; {
    go = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "go";

          go = mkOption {
            type = types.package;
            description = "go package used";
            example = "pkgs.go_1_18";
            default = pkgs.go;
          };

          modules = mkOption {
            type = types.path;
            description = "path to gomod2nix.toml file";
            default = config.src + "/gomod2nix.toml";
          };
        };
      };
    };

    out_go = mkOption {
      type = types.package;
      readOnly = true;
    };

    out_go_env = mkOption {
      type = types.package;
      readOnly = true;
    };
  };

  config = let
    cfg = config.go;
    gomod2nix = sources.gomod2nix.legacyPackages.${pkgs.system};
    goEnv = gomod2nix.mkGoEnv { pwd = src; };
  in lib.mkIf cfg.enable {
    out_go = gomod2nix.buildGoApplication {
      pname = config.name;
      version = config.version;
      src = config.src;
      modules = cfg.modules;
    };
    out_go_env = config.go.go;
    dev_commands = [
      gomod2nix.gomod2nix
    ];
    dev_apps = [
      goEnv
    ];
  };
}
