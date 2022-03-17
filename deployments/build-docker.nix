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

          command = mkOption {
            type = with types; listOf str;
            description = "command to call from a docker container";
            example = ''[ "''${config.out_app_linux}/bin/start-microservice" "--port" "8080" ]'';
          };

          env = mkOption {
            type = with types; attrsOf str;
            description = "environment variables";
            default = {};
          };

          user = mkOption {
            type = types.str;
            description = "user/group to run container under";
            example = "65535:65535";
            default = "0";
          };

          exposed_ports = mkOption {
            type = with types; listOf str;
            description = "list of ports that should be exposed";
            example = ''[ "8080/tcp" ]'';
            default = [];
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
      tag = cfg.tag;
      created = "now";
      contents = cfg.contents;
      config = {
        cmd = cfg.command;
        user = cfg.user;
        exposedports = lib.genAttrs cfg.exposed_ports (_: {});
        env = lib.mapAttrsToList (name: value: "${name}=${value}" ) cfg.env;
      };
    };
  };
}
