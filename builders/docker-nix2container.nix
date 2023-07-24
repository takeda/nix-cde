{ build_system, config, lib, sources, ... }:

{
  options = with lib; {
    docker = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "docker";

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
    nix2container = sources.nix2container.packages.${build_system}.nix2container;
  in lib.mkIf config.docker.enable {
    out_docker = nix2container.buildImage {
      name = config.name;
      contents = cfg.contents;
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
