{ config, host_system, lib, pkgs, sources, ... }:

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
            type = with types; functionOf (listOf package);
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
    poetry = python: let
      poetry2nix = sources.poetry2nix.legacyPackages.${host_system}.overrideScope' (p2nself: p2nsuper: {
        defaultPoetryOverrides = p2nsuper.defaultPoetryOverrides.extend cfg.overrides;
      });
      common_cfg = {
        inherit python;
        projectDir = config.src;
        preferWheels = cfg.prefer_wheels;
      };
    in {
      app = poetry2nix.mkPoetryApplication common_cfg // {
        doCheck = cfg.check_command != null;
        checkPhase = cfg.check_command;
      };
      env = poetry2nix.mkPoetryEnv common_cfg // {
        editablePackageSources = cfg.modules;
        extraPackages = cfg.extra_shell_packages;
      };
      packages = poetry2nix.mkPoetryPackages {
        inherit python;
        projectDir = config.src;
      };
    };

    # python environment used for dev shell
    python_env = if (cfg.inject_app_env && builtins.pathExists (config.src + "/poetry.lock"))
    then (poetry cfg.package).env
    else cfg.package; # if there's no poetry project, just expose python itself

  in lib.mkIf cfg.enable {
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
