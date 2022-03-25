{ config, lib, pkgs, ... }:

{
  options = {
    framework.serverless = with lib; {
      enable = mkEnableOption "serverless framework";

      nodejs = mkOption {
        type = types.package;
        description = "nodejs to use";
        example = "pkgs.nodejs";
        default = pkgs.nodejs;
      };

      package = mkOption {
        type = types.path;
        description = "npm package.json file";
        example = "./package.json";
      };
      package_lock = mkOption {
        type = types.path;
        description = "npm package-lock.json file";
        example = "./package-lock.json";
      };
    };
  };

  config = let
    cfg = config.framework.serverless;

    # to prevent rebuilding serverless packages continously on any change
    # we generate a derivation (in this case it is a directory) that contains nothing,
    # just those two files
    serverless_project = pkgs.runCommandLocal "${config.name}-serverless-env" {} ''
      mkdir $out
      cp ${cfg.package} $out/package.json
      cp ${cfg.package_lock} $out/package-lock.json
    '';

    node_modules = pkgs.npmlock2nix.node_modules {
      src = serverless_project;
      nodejs = cfg.nodejs;
      nativeBuildInputs = [
        pkgs.bash
        pkgs.python3
      ]
      ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin pkgs.darwin.cctools;
    };
  in lib.mkIf cfg.enable {
    dev_apps = [
      cfg.nodejs
      node_modules
    ];
  };
}
