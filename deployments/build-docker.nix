{ config, lib, pkgs_native, ... }:

{
  options = with lib; {
    docker = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "docker";

          stream = mkOption {
            type = types.bool;
            description = "should docker container be streamed (useful for big containers)";
            default = false;
          };

          max_layers = mkOption {
            type = types.ints.between 1 125;
            description = "maximum number of layers to create";
            default = 100;
          };

          tag = mkOption {
            type = with types; nullOr str;
            description = "tag for the docker image";
            default = null;
          };

          contents = mkOption {
            type = with types; listOf package;
            description = "derivations that will make the root of the container";
            default = [];
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

          extra_commands = mkOption {
            type = with types; lines;
            description = "shell commands to run while building final layer";
            default = "";
          };

          fakeroot_commands = mkOption {
            type = with types; lines;
            description = "shell commands that might change permissions";
            default = "";
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
    buildImageTool = with pkgs_native.dockerTools; if cfg.stream
    then streamLayeredImage
    else buildLayeredImage;
  in lib.mkIf config.docker.enable {
    out_docker = buildImageTool {
      name = config.name;
      maxLayers = cfg.max_layers;
      tag = cfg.tag;
      created = "now";
      contents = cfg.contents;
      extraCommands = cfg.extra_commands;
      fakeRootCommands = cfg.fakeroot_commands;
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
