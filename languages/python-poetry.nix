{ config, lib, pkgs, sources, src, ... }:

{
  options = with lib; {
    python = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "python";

          package = mkOption {
            type = types.package;
            description = "python package";
            example = "python311";
          };

          modules = mkOption {
            type = with types; attrsOf path;
            description = "mapping of python module => path, used primarily for shell environment to install package in an editable mode (note that root of the source dir is already added under src name)";
            example = "{ python_microservice = ./python_microservice; }";
            default = {};
          };

          extra_shell_packages = mkOption {
            type = with types; functionTo (listOf package);
            description = "additional packages to include for development (for example pip for serverless)";
            example = "ps: [ ps.pip ]";
            default = ps: [ ];
          };

          inject_app_env = mkOption {
            type = types.bool;
            description = "include the app in the dev shell";
            default = true;
          };

          prefer_wheels = mkOption {
            type = types.bool;
            description = "prefer using wheels for packages instead of building them";
            default = false;
          };

          overrides = mkOption {
            type = types.unspecified;
            description = "override list for poetry packages";
            example = ''
              self: super:
              {
                psutil = super.psutil.overridePythonAttrs (
                  old: {
                    buildInputs = (old.buildInputs or []) ++
                      lib.optional stdenv.isDarwin pkgs.darwin.apple_sdk.frameworks.IOKit;
                  }
                );
              }
            '';
            default = self: super: {};
          };

          build_check_groups = mkOption {
            type = with types; listOf str;
            description = "list of dependency groups to install for running checks (typically you might want to specify \"dev\")";
            example = ''[ "dev" ]'';
            default = [ "dev" ];
          };

          check_command = mkOption {
            type = with types; nullOr str;
            description = "command to run to execute unit tests";
            example = "pytest --no-cov";
            default = null;
          };
        };
      };
    };

    out_pypackages = mkOption {
      type = types.anything;
      readOnly = true;
    };

    out_python = mkOption {
      type = types.package;
      readOnly = true;
    };
  };

  config = let
    cfg = config.python;
    poetry2nix = sources.poetry2nix.lib.mkPoetry2Nix { inherit pkgs; };
    poetry = python: let
      common_cfg = {
        inherit python;
        projectDir = src;
        preferWheels = cfg.prefer_wheels;
        overrides = poetry2nix.defaultPoetryOverrides.extend cfg.overrides;
      };
    in {
      app = poetry2nix.mkPoetryApplication (common_cfg // {
        doCheck = cfg.check_command != null;
        checkGroups = if (cfg.check_command == null) then [] else cfg.build_check_groups;
        checkPhase = cfg.check_command;
      });
      env = poetry2nix.mkPoetryEnv (common_cfg // {
        editablePackageSources = cfg.modules;
        extraPackages = cfg.extra_shell_packages;
      });
      packages = poetry2nix.mkPoetryPackages {
        inherit python;
        projectDir = src;
      };
    };

    # python environment used for dev shell
    python_env = if (cfg.inject_app_env && builtins.pathExists (src + "/poetry.lock"))
    then (poetry cfg.package).env
    else cfg.package; # if there's no poetry project, just expose python itself

  in lib.mkIf config.python.enable {
    dev_commands = [
      pkgs.poetry
    ];
    dev_apps = [
      python_env
    ];

    out_pypackages = (poetry cfg.package).packages;
    out_python = (poetry cfg.package).app;
  };
}
