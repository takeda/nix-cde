{ config, lib, pkgs, sources, ... }:

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
      npmlock2nix_version = mkOption {
        type = types.enum [ "v1" "v2"];
        description = "version of npmlock2nix to use v1 - old and stable (doesn't work beyond node 14), v2 - new and experimental";
        example = "v1";
        default = "v2";
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
    npmlock2nix = import sources.npmlock2nix { inherit pkgs lib; };

    # to prevent rebuilding serverless packages continously on any change
    # we generate a derivation (in this case it is a directory) that contains nothing,
    # just those two files
    serverless_project = pkgs.runCommandLocal "${config.name}-serverless-env" {} ''
      mkdir $out
      cp ${cfg.package} $out/package.json
      cp ${cfg.package_lock} $out/package-lock.json
    '';

    node_modules = npmlock2nix.${cfg.npmlock2nix_version}.node_modules {
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
