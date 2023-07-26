{ config, lib, pkgs_native, sources, ... }:

{
  options = with lib; {
    docker = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "docker";

          max_layers = mkOption {
            type = types.ints.between 1 125;
            description = "maximum number of layers to create";
            default = 1;
          };

          tag = mkOption {
            type = with types; nullOr str;
            description = "tag for the docker image";
            default = null;
          };

          copy_to_root = mkOption {
            type = with types; nullOr unspecified;
            description = "list of derivations copied in the image root directory";
            example = ''
              [
                pkgs.buildEnv {
                  name = "root";
                  paths = [ pkgs.bashInteractive pkgs.coreutils ];
                  pathsToLink = [ "/bin" ];
                }
              ]
            '';
            default = null;
          };

          entrypoint = mkOption {
            type = with types; nullOr (listOf str);
            description = "entrypoint for calling the docker container";
            example = ''[ "''${config.out_python}/bin/manager" ]'';
            default = null;
          };

          command = mkOption {
            type = with types; nullOr (listOf str);
            description = "command to call from a docker container";
            example = ''[ "''${config.out_python}/bin/start-microservice" "--port" "8080" ]'';
            default = null;
          };

          env = mkOption {
            type = with types; nullOr (attrsOf str);
            description = "environment variables";
            default = null;
          };

          user = mkOption {
            type = with types; nullOr str;
            description = "user/group to run container under";
            example = "65535:65535";
            default = null;
          };

          exposed_ports = mkOption {
            type = with types; nullOr (listOf str);
            description = "list of ports that should be exposed";
            example = ''[ "8080/tcp" ]'';
            default = null;
          };

          working_dir = mkOption {
            type = with types; nullOr str;
            description = "working directory of the entry point process";
            example = "/app";
            default = null;
          };

          volumes = mkOption {
            type = with types; nullOr (listOf str);
            description = "list of volumes";
            example = ''[ "/var/my-app-data" "/etc/some-config.d" ]'';
            default = null;
          };

          perms = mkOption {
            type = with types; listOf attrs;
            description = "permissions to set in the produced image";
            example = ''
              [
                {
                  path = "a store path";
                  regex = ".*";
                  mode = "0664";
                }
              ]
            '';
            default = [];
          };

          layers = mkOption {
            type = with types; listOf unspecified;
            description = "list of layers to include";
            default = [];
          };

          initialize_nix_db = mkOption {
            type = types.bool;
            description = "initialize nix database with all stored paths (this is used for images where you will want to have nix command e.g. CI)";
            default = false;
          };
        };
      };
      default = {};
    };

    out_docker = mkOption {
      type = types.package;
      readOnly = true;
    };
  };
  config = let
    cfg = config.docker;
    nix2container = sources.nix2container.packages.${pkgs_native.system}.nix2container;
  in lib.mkIf config.docker.enable {
    _module.args = {
      inherit nix2container;
    };
    out_docker = nix2container.buildImage {
      name = config.name;
      maxLayers = cfg.max_layers;
      tag = cfg.tag;
      copyToRoot = cfg.copy_to_root;
      perms = cfg.perms;
      initializeNixDatabase = cfg.initialize_nix_db;
      layers = cfg.layers;
      config = lib.optionalAttrs (cfg.user != null) {
        user = cfg.user;
      } // lib.optionalAttrs (cfg.exposed_ports != null) {
        exposedports = lib.genAttrs cfg.exposed_ports (_: {});
      } // lib.optionalAttrs (cfg.env != null) {
        env = lib.mapAttrsToList (name: value: "${name}=${value}" ) cfg.env;
      } // lib.optionalAttrs (cfg.command != null) {
        cmd = cfg.command;
      } // lib.optionalAttrs (cfg.entrypoint != null) {
        entrypoint = cfg.entrypoint;
      } // lib.optionalAttrs (cfg.working_dir != null) {
        workingdir = cfg.working_dir;
      } // lib.optionalAttrs (cfg.volumes != null) {
        volumes = lib.genAttrs cfg.volumes (_: {});
      };
    };
  };
}
