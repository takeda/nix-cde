{ config, lib, pkgs, ... }:

{
  options = with lib; {
    bundle = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "bundle";

          chroot_flags = mkOption {
            type = types.str;
            description = "additional flags to use with chroot";
            default = "";
          };

          target = mkOption {
            type = types.package;
            description = "package to bundle";
          };

          command = mkOption {
            type = types.str;
            description = "command to run within the main package";
          };

          extra_targets = mkOption {
            type = with types; listOf package;
            description = "additional packages to include into the build";
            default = [];
          };

          init_script = mkOption {
            type = types.str;
            description = "init script to execute on startup";
            default = "";
          };
        };
      };
      default = {};
    };

    out_bundle = mkOption {
      type = types.package;
      readOnly = true;
    };
  };

  config = let
    cfg = config.bundle;
  in lib.mkIf config.bundle.enable {
    out_bundle = pkgs.nix-bundle-lib.nix-bootstrap-path {
      target = cfg.target;
      extraTargets = cfg.extra_targets;
      initScript = cfg.init_script;
      nixUserChrootFlags = cfg.chroot_flags;
      run = cfg.command;
    };
  };
}
